Rails.application.routes.draw do
  devise_for :usuarios, controllers: { sessions: 'usuarios/sessions' }, path: 'auth'

  resources :productos
  resources :usuarios

  # Root: formulario de login de Devise para Usuario
  devise_scope :usuario do
    root to: "devise/sessions#new"
  end
end
