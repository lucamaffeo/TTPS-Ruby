Rails.application.routes.draw do
  resources :productos do
    # Gestión privada de canciones (CRUD)
    resources :canciones, only: [:index, :new, :create, :edit, :update, :destroy]
  end
  get "productos_filtrados", to: "productos#productos_filtrados"
  
  get '/buscar_cliente', to: 'clientes#buscar_por_dni'


  resources :ventas, controller: "venta"

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
    resources :productos, only: [ :index, :show ] do
      member do
        get :canciones
      end
    end
  end

  namespace :admin do
    get 'dashboard', to: 'dashboard#index', as: :dashboard
  end

  # Catch-all: cualquier URL inexistente va al storefront
end
