Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :orders, only: [:create, :update, :destroy, :show, :index]
      get 'trades', to: 'runtime_data#trades'
      get 'positions', to: 'runtime_data#positions'
      get 'holdings', to: 'runtime_data#holdings'
      get 'funds', to: 'runtime_data#funds'
      get 'depth/:symbol', to: 'runtime_data#depth'
      get 'orderbook/:symbol', to: 'runtime_data#orderbook'
      get 'executions', to: 'runtime_data#executions'

      get 'margin', to: 'margin#index'
      post 'margin/calculate', to: 'margin#calculate'

      get 'risk/portfolio', to: 'risk#portfolio'
      get 'risk/strategies', to: 'risk#strategies'
      get 'risk/snapshot', to: 'risk#snapshot'
      post 'risk/kill-switch', to: 'risk#kill_switch'

      get 'charges', to: 'accounting#charges'
      get 'settlements', to: 'accounting#settlements'
      get 'corporate-actions', to: 'accounting#corporate_actions'
      get 'dividends', to: 'accounting#dividends'
      get 'tax-summary', to: 'accounting#tax_summary'
      get 'cashflows', to: 'accounting#cashflows'

      post 'replay/start', to: 'replay#start'
      post 'replay/pause', to: 'replay#pause'
      post 'replay/resume', to: 'replay#resume'
      get 'replay/status', to: 'replay#status'
    end
  end
end
