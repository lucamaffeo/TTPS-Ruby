Rails.application.routes.draw do
  resources :productos
  get "productos_filtrados", to: "productos#productos_filtrados"
  resources :venta
  devise_for :usuarios, controllers: { sessions: "usuarios/sessions" }, path: "auth"

  resources :usuarios do
    member do
      patch :reset_password_default
    end
  end

  # Root: storefront
  root "storefront/productos#index"
  namespace :storefront do
    resources :productos, only: [ :index, :show ]
  end
end
