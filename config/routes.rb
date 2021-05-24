Rails.application.routes.draw do
  mount Qa::Engine => '/qa'

  get 'searches/index'
  get 'searches/show'
  get 'home_page/index'

  resources :searches

  get 'search/simple'
  get 'search/show'
  resources :search
  
  root 'home_page#index'

  get 'image_zoom_large' => 'image_zoom_large#index'
  get 'image_zoom_large/alt' => 'image_zoom_large#alt'

  # added (ja)

  get 'iiif/index'
  #get 'iiif/show'
  get 'iiif/:id/:region/:size/:rotation/:quality' , controller: :iiif, action: :show
  get 'iiif/:id/info.json' , controller: :iiif, action: :show
  get 'iiif/manifest/:register_id' , controller: :iiif, action: :manifest
  get 'iiif/manifest' => 'iiif#manifest'
  get 'iiif/canvas/:folio_id' , controller: :iiif, action: :canvas
  get 'iiif/canvas' => 'iiif#canvas'
  get 'iiif/download/:folio_id' , controller: :iiif, action: :download
  get 'iiif/download' => 'iiif#download'

  resources :iiif

  get 'entry/:id' , controller: :entry, action: :show

  resources :entry

  get 'browse/index'
  get 'browse/registers'
  get 'browse/people'
  get 'browse/places'
  get 'browse/groups'
  get 'browse/subjects'
  get 'about/index'
  get 'northernway/index'
  get 'northernway_about/index'
  get 'browse' => 'browse#index'
  get 'about' => 'about#index'
  get 'northernway' => 'northernway#index'
  get 'northernway/about' => 'northernway_about#index'



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
