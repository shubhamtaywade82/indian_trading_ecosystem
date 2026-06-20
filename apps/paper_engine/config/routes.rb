Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Orders
      resources :orders, only: [:index, :show, :create, :update, :destroy] do
        member do
          delete :cancel
        end
      end

      # Positions, Holdings, Trades, Funds
      get 'positions',  to: 'runtime_data#positions'
      get 'holdings',   to: 'runtime_data#holdings'
      get 'trades',     to: 'runtime_data#trades'
      get 'funds',      to: 'runtime_data#funds'
      get 'depth/:symbol', to: 'runtime_data#depth'

      # Margin
      get  'margin',           to: 'margin#index'
      post 'margin/calculate', to: 'margin#calculate'

      # Risk
      get  'risk/portfolio',  to: 'risk#portfolio'
      get  'risk/strategies', to: 'risk#strategies'
      get  'risk/snapshot',   to: 'risk#snapshot'
      post 'risk/kill_switch', to: 'risk#kill_switch'

      # Accounting
      get 'accounting/charges',          to: 'accounting#charges'
      get 'accounting/settlements',      to: 'accounting#settlements'
      get 'accounting/corporate_actions', to: 'accounting#corporate_actions'
      get 'accounting/dividends',        to: 'accounting#dividends'
      get 'accounting/tax_summary',      to: 'accounting#tax_summary'
      get 'accounting/cashflows',        to: 'accounting#cashflows'

      # Broker Profiles
      resources :broker_profiles, only: [:index, :show, :create, :update]

      # Replay
      post 'replay/start', to: 'replay#start'
      post 'replay/stop',  to: 'replay#stop'
      get  'replay/status', to: 'replay#status'
    end
  end

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
