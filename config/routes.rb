Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  root 'pages#index'

  require 'sidekiq/web'
  require 'sidekiq-status/web'
  mount Sidekiq::Web => '/sidekiq'

  # Target URL Sample:
  # 
  # http://ubooksdevelopment.s3-website-us-east-1.amazonaws.com/documents_html/25/25_optimized.html

  scope '/api' do
    scope '/v1' do
      resources :hacker_news_posts, only: [:index]
      resources :peru_quiosco_pubs, only: [:index]
      resources :foros_peru_posts, only: [:index]
      resources :documents, only: [:index, :create, :show] do
        member do
          get :search
          get :ocr
          get :pno
          get :process_mobile_pages
        end
        collection do
          get :backfilled
        end
      end

      resources :queues do
        collection do
          get 'check_sidekiq'
          get 'active_queues'
          get 'exec_sidekiq'
        end
      end

      resources :backfills, only: [:index]

      get 'backfill_all_mobile_pages' => 'backfills#backfill_all_mobile_pages'

      get 'clean_data' => 'backfills#clean_data'
      get 'delete_all_hn_posts' => 'backfills#delete_all_hn_posts'

      get 'init_hn_worker' => 'backfills#init_hn_worker'
      get 'hn_upload/:id' => 'backfills#hn_upload'

      get 'init_pq_worker' => 'backfills#init_pq_worker'
      get 'pq_upload/:id' => 'backfills#pq_upload'

      get 'init_fp_worker' => 'backfills#init_fp_worker'
    end
  end

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
