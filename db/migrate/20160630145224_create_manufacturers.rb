class CreateManufacturers < ActiveRecord::Migration
  def change
    create_table :spree_manufacturers do |t|
      t.string :name
      t.string :slug
      t.text :abstract
      t.text :description

      t.string :address1
      t.string :address2
      t.string :city
      t.string :zipcode
      t.string :phone
      t.string :state_name
      t.string :alternative_phone
      t.references :state
      t.references :country

      t.string :meta_title
      t.string :meta_description
      t.string :meta_keywords

      t.timestamps
    end

    add_index :spree_manufacturers, [:name], :name => 'index_spree_manufacturers_on_name'
    add_index :spree_manufacturers, [:slug], :name => 'index_spree_manufacturers_on_slug', :unique => true
  end
end