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

      def update_positions
        ActiveRecord::Base.transaction do
          params[:positions].each do |id, index|
            model_class.find(id).set_list_position(index)
          end
        end

        respond_to do |format|
          format.js { render text: 'Ok' }
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
          @collection = @search.result
        end
      end

      def manufacturer_params
        attributes = [:name, :abstract, :description, :why_we_like_it, :meta_title, :meta_description, :meta_keywords,
                      :slug, :address1, :address2, :city, :zipcode, :country_id, :micro_region_id, :phone,
                      address: permitted_address_attributes]

        params.require(:manufacturer).permit(attributes)
      end
    end
  end
end