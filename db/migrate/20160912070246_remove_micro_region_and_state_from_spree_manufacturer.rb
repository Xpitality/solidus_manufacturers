class RemoveMicroRegionAndStateFromSpreeManufacturer < ActiveRecord::Migration
  def change
    remove_column :spree_manufacturers, :micro_region, :string
    remove_reference :spree_manufacturers, :state
  end
end
