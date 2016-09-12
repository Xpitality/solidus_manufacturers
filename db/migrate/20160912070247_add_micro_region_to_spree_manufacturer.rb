class AddMicroRegionToSpreeManufacturer < ActiveRecord::Migration
  def change
    add_reference :spree_manufacturers, :micro_region, index: false
  end
end
