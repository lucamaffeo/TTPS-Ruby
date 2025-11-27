Rails.application.routes.draw do
  resources :venta
  devise_for :usuarios, controllers: { sessions: 'usuarios/sessions' }, path: 'auth'

  resources :productos
  resources :usuarios
  resources :venta
  # Root: storefront
  root "storefront/productos#index"

  # STORE FRONT (vista pública)
  namespace :storefront do
    # La raíz del storefront ahora es la raíz principal de la app.
    # Mantenemos las rutas de productos para el show.
    resources :productos, only: [:index, :show]
  end
end
