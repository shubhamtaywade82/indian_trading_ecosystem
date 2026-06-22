# frozen_string_literal: true

require 'csv'
require 'net/http'

namespace :import do
  desc "Import all tradeable instruments and segments from Dhan HQ API scrip master"
  task instruments: :environment do
    url = ENV.fetch('SCRIP_MASTER_URL', 'https://images.dhan.co/api-data/api-scrip-master.csv')
    limit = ENV['LIMIT']&.to_i
    
    puts "Starting instrument sync from #{url}..."
    uri = URI(url)
    
    # Download the CSV
    temp_file = Rails.root.join('tmp', 'api-scrip-master.csv')
    Dir.mkdir(Rails.root.join('tmp')) unless Dir.exist?(Rails.root.join('tmp'))
    
    puts "Downloading CSV to #{temp_file}..."
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      File.write(temp_file, response.body)
      puts "Download complete (#{File.size(temp_file)} bytes)."
    else
      abort "Failed to download scrip master file: #{response.message}"
    end

    # Parse and import in batches
    puts "Parsing and importing instruments..."
    count = 0
    
    CSV.foreach(temp_file, headers: true) do |row|
      break if limit && count >= limit

      # Match headers for compact/detailed formats
      exch_code = (row['SEM_EXM_EXCH_ID'] || row['EXCH_ID'] || 'NSE').to_s.upcase
      raw_segment = row['SEM_SEGMENT'] || row['SEGMENT']
      symbol = row['SM_SYMBOL_NAME'] || row['SYMBOL_NAME']
      trading_symbol = row['SEM_TRADING_SYMBOL'] || row['TRADING_SYMBOL'] || row['SEM_CUSTOM_SYMBOL'] || row['DISPLAY_NAME']
      security_id = row['SEM_SMST_SECURITY_ID'] || row['SEM_SM_ID'] || row['SEM_SECURITY_ID'] || row['security_id'] || row['UNDERLYING_SECURITY_ID']
      isin = row['SEM_ISIN'] || row['ISIN']
      inst_type = row['SEM_EXCH_INSTRUMENT_TYPE'] || row['INSTRUMENT_TYPE'] || row['SEM_INSTRUMENT_NAME'] || row['INSTRUMENT']
      lot_size = (row['SEM_LOT_UNITS'] || row['LOT_SIZE'] || 1).to_i
      expiry_str = row['SEM_EXPIRY_DATE'] || row['SM_EXPIRY_DATE']
      strike_str = row['SEM_STRIKE_PRICE'] || row['STRIKE_PRICE']
      opt_type = row['SEM_OPTION_TYPE'] || row['OPTION_TYPE']
      underlying_sym = row['UNDERLYING_SYMBOL'] || symbol

      next if symbol.blank? || exch_code.blank? || security_id.blank?

      # 1. Populating the primary Security Master (exchanges, segments, instruments, derivatives)
      exchange = Exchange.find_or_create_by!(code: exch_code) do |e|
        e.name = "#{exch_code} Stock Exchange"
      end

      # Map segment names
      segment_code = case raw_segment&.upcase
                when 'E', 'EQUITY' then "#{exch_code}_EQ"
                when 'D', 'DERIVATIVES', 'FNO' then "#{exch_code}_FNO"
                when 'M', 'COMMODITY' then "MCX_FUT"
                when 'C', 'CURRENCY' then "CDS_FNO"
                else "#{exch_code}_#{raw_segment}"
                end

      segment = Segment.find_or_create_by!(code: segment_code) do |s|
        s.exchange = exchange
        s.name = "#{exch_code} #{raw_segment} Segment"
      end

      # Parse standardized type
      mapped_type = inst_type.to_s.downcase
      normalized_type = if mapped_type.include?('opt')
                          'option'
                        elsif mapped_type.include?('fut')
                          'future'
                        elsif mapped_type.include?('index')
                          'index'
                        else
                          'equity'
                        end

      instrument_attrs = {
        exchange: exchange,
        segment: segment,
        symbol: symbol,
        trading_symbol: trading_symbol,
        isin: isin,
        instrument_type: normalized_type,
        name: trading_symbol
      }

      # Primary Instrument
      instrument = Instrument.find_by(symbol: symbol, exchange_id: exchange.id)
      if instrument
        # Update security_id if it was a temporary placeholder
        if instrument.security_id >= 900_000_000
          # We need to update the primary key column or delete and recreate
          # Let's delete the placeholder so we can save the new one cleanly without PG duplicate key errors
          instrument.destroy
          instrument = Instrument.new(security_id: security_id.to_i)
        end
      else
        instrument = Instrument.new(security_id: security_id.to_i)
      end
      instrument.assign_attributes(instrument_attrs)
      
      if instrument.save
        count += 1
        
        # Populate F&O details in Primary Security Master
        if %w[future option].include?(normalized_type) && expiry_str.present?
          expiry = Date.parse(expiry_str) rescue nil
          if expiry
            # Find or create underlying instrument record
            underlying_inst = Instrument.find_by(symbol: underlying_sym, exchange_id: exchange.id)
            unless underlying_inst
              # Create a placeholder underlying instrument
              underlying_inst = Instrument.create!(
                security_id: 900_000_000 + rand(99_999_999),
                symbol: underlying_sym,
                exchange: exchange,
                segment: segment,
                instrument_type: underlying_sym.to_s.upcase.include?('NIFTY') || underlying_sym.to_s.upcase.include?('SENSEX') ? 'index' : 'equity',
                active: true
              )
            end
            if underlying_inst
              underlying = Underlying.find_or_create_by!(instrument: underlying_inst, asset_class: underlying_inst.instrument_type.titleize)
              
              contract_type = if normalized_type == 'future'
                                'future'
                              else
                                (opt_type.to_s.upcase == 'PE' || opt_type.to_s.upcase == 'PUT') ? 'put_option' : 'call_option'
                              end

              deriv = DerivativeContract.find_or_create_by!(security_id: security_id.to_i) do |d|
                d.underlying = underlying
                d.expiry_date = expiry
                d.contract_type = contract_type
                d.lot_size = lot_size
                d.tick_size = 0.05
              end

              if normalized_type == 'future'
                FutureContract.find_or_create_by!(derivative_contract: deriv)
              else
                OptionContract.find_or_create_by!(
                  derivative_contract: deriv,
                  strike_price: strike_str.to_f,
                  option_type: (opt_type.to_s.upcase == 'PE' || opt_type.to_s.upcase == 'PUT') ? 'PE' : 'CE'
                )
              end
            end
          end
        end

        # 2. Populating the core execution loop namespace (Core::Instrument)
        # Note: Core::Instrument uses (symbol, exchange) index and does not have security_id
        core_inst = Core::Instrument.find_or_initialize_by(symbol: symbol, exchange: exch_code)
        core_inst_attrs = {
          segment: segment_code,
          instrument_type: normalized_type == 'option' ? 'options' : (normalized_type == 'future' ? 'futures' : normalized_type),
          isin: isin,
          lot_size: lot_size,
          tick_size: 0.05,
          name: trading_symbol
        }
        core_inst.assign_attributes(core_inst_attrs)
        
        if core_inst.save
          # Create contracts under Core::OptionContract or Core::FutureContract
          if normalized_type == 'option' && expiry_str.present?
            expiry = Date.parse(expiry_str) rescue nil
            if expiry
              Core::OptionContract.find_or_create_by!(
                instrument: core_inst,
                underlying_symbol: underlying_sym,
                expiry_date: expiry,
                strike_price: strike_str.to_f,
                option_type: (opt_type.to_s.upcase == 'PE' || opt_type.to_s.upcase == 'PUT') ? 'PE' : 'CE'
              )
            end
          elsif normalized_type == 'future' && expiry_str.present?
            expiry = Date.parse(expiry_str) rescue nil
            if expiry
              Core::FutureContract.find_or_create_by!(
                instrument: core_inst,
                underlying_symbol: underlying_sym,
                expiry_date: expiry
              )
            end
          end
        end
      else
        puts "Skipped invalid instrument row: #{instrument.errors.full_messages.join(', ')}"
      end

      if count % 1000 == 0
        puts "Synced #{count} instruments..."
      end
    end

    # Clean up temp file
    File.delete(temp_file) if File.exist?(temp_file)
    
    puts "Completed syncing #{count} instruments and derivative contracts successfully."
  end
end
