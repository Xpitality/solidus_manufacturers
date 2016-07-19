class AddTaxonToManufacturer < ActiveRecord::Migration
  def change
    add_reference :spree_manufacturers, :taxon, index: false
  end
end
