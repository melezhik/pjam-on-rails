Ui::Application.routes.draw do


  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
    # root 'welcome#index'

    root 'projects#index'

    resources :welcome 

    resource :activity do
    end

    resource :settings do
    end

    resources :projects do


        member do
            get 'last_successfull_build'
            get 'activity'
        end

        resources :builds do

            member do
                get     'changes'
                get     'list'
                get     'full_log'
                get     'configuration'
                get     'artefacts/*archive/', to: 'builds#download'
                post    'lock'
                post    'unlock'
                post    'release'
                post    'revert'
            end

            resources :logs do
            end

            resources :shanpshots do
            end
    
        end
        
        resources :sources do
            member do
                post 'on'
                post 'off'
                post 'app'
            end
        end
    end
     

  # root to: "welcome#index"

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
