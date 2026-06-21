# frozen_string_literal: true

module Api
  module V1
    class RuntimeConfigsController < ApplicationController
      # GET /api/v1/runtime_configs
      def index
        configs = Core::RuntimeConfig.all
        render json: configs
      end

      # GET /api/v1/runtime_configs/:id
      def show
        config = Core::RuntimeConfig.find(params[:id])
        render json: config
      end

      # POST /api/v1/runtime_configs
      def create
        config = Core::RuntimeConfig.create!(config_params)
        render json: config, status: :created
      end

      # PATCH/PUT /api/v1/runtime_configs/:id
      def update
        config = Core::RuntimeConfig.find(params[:id])
        config.update!(config_params)
        render json: config
      end

      private

      def config_params
        params.require(:runtime_config).permit(:name, :mode, :market_data_source, :core_execution_profile_id, :settings)
      end
    end
  end
end
