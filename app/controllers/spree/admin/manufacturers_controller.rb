module Spree
  module Admin
    class ManufacturersController < ResourceController

      def index
        respond_with(@collection) do |format|
          format.html
        end
      end

      def show
        redirect_to edit_admin_manufacturer_path(@manufacturer)
      end

      def create
        @manufacturer = Spree::Manufacturer.new(manufacturer_params)
        if @manufacturer.save

          flash[:success] = Spree.t(:created_successfully)
          redirect_to edit_admin_manufacturer_url(@manufacturer)
        else
          render :new, status: :unprocessable_entity
        end
      end

      private

      def find_resource
        Spree::Manufacturer.friendly.find(params[:id])
      end

      def collection
        return @collection if @collection.present?
        if request.xhr? && params[:q].present?
          @collection = Spree::Manufacturer
          .where("spree_manufacturers.title #{LIKE} :search",
                 { search: "#{params[:q].strip}%" })
          .limit(params[:limit] || 100)
        else
          @search = Spree::Manufacturer.ransack(params[:q])
          @collection = @search.result.page(params[:page]).per(Spree::Config[:admin_products_per_page])
        end
      end

      def manufacturer_params
        attributes = [:name, :abstract, :description, :meta_title, :meta_description, :meta_keywords,
                      :slug, :address1, :address2, :city, :zipcode, :country_id, :state_id, :phone,
                      address: permitted_address_attributes]

        params.require(:manufacturer).permit(attributes)
      end
    end
  end
end