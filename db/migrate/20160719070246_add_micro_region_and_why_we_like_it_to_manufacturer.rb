class AddMicroRegionAndWhyWeLikeItToManufacturer < ActiveRecord::Migration
  def change
    add_column :spree_manufacturers, :micro_region, :string
    add_column :spree_manufacturers, :why_we_like_it, :text

    add_column :spree_manufacturer_translations, :why_we_like_it, :text
  end
end
