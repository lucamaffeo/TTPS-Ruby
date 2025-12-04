Rails.application.routes.draw do
  resources :productos
  get "productos_filtrados", to: "productos#productos_filtrados"

  resources :venta

  # Devise sin rutas de registro (sign_up deshabilitado)
  devise_for :usuarios, controllers: { sessions: "usuarios/sessions" }, path: "auth", skip: [:registrations]

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

  # Catch-all: cualquier URL inexistente va al storefront
  match "*unmatched", to: "storefront/productos#index", via: :all
end
