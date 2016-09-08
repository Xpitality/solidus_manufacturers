class AddPositionToManufacturer < ActiveRecord::Migration
  def change
    add_column :spree_manufacturers, :position, :integer
  end
end
