class AddManufacturerToProduct < ActiveRecord::Migration
  def change
    add_reference :spree_products, :manufacturer, index: true
  end
end
