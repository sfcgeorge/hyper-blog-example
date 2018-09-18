Rails.application.routes.draw do
  mount Hyperloop::Engine => '/hyperloop'
  resources :sessions
  resources :comments
  resources :posts
  resources :blogs
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
