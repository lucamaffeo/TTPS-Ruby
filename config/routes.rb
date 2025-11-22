Rails.application.routes.draw do
  devise_for :usuarios, path: "auth"

  resources :productos
  resources :usuarios

  # Root: formulario de login de Devise para Usuario
  devise_scope :usuario do
    root to: "devise/sessions#new"  
  end

  # STORE FRONT (vista pública)
  namespace :storefront do
    root "productos#index"            # GET /storefront
    resources :productos, only: [:index, :show]
  end
end
