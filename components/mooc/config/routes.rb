Mooc::Engine.routes.draw do
  post '/units', to: 'units#show'
  get '/units/error', to: 'units#error'

  devise_for :users, class_name: 'Mooc::User', controllers: { sessions: 'shared/sessions', registrations: 'shared/registrations' }, path: '', path_names: { sign_up: :join, sign_in: :login, sign_out: :logout }, module: :devise

  resources :units, only: [:show] do
    resources :questions, only: [:index, :create, :show, :update, :destroy]
  end

  match '/parser' => "parser#parser", via: [:post]
  match '/parser' => "parser#options", via: [:options]
end
