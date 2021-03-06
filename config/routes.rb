Spree::Core::Engine.routes.draw do
  namespace :admin do
    resources :manufacturers do
      resources :images, controller: 'manufacturer_images' do
        collection do
          post :update_positions
        end
      end
      collection do
        post :update_positions
      end
    end
  end
end
