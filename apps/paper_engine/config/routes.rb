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
    end
  end
end
