module Spree
  module Admin
    class ManufacturerImagesController < ResourceController
      before_action :load_data

      create.before :set_viewable
      update.before :set_viewable

      def index
      end

      private

      def model_class
        Spree::ManufacturerImage
      end

      def location_after_destroy
        admin_manufacturer_images_url(@manufacturer)
      end

      def location_after_save
        admin_manufacturer_images_url(@manufacturer)
      end

      def load_data
        @manufacturer = Spree::Manufacturer.friendly.find(params[:manufacturer_id])
      end

      def set_viewable
        @manufacturer_image.viewable_type = 'Spree::Manufacturer'
        @manufacturer_image.viewable_id = params[:manufacturer_image][:manufacturer_id]
      end
    end
  end
end
