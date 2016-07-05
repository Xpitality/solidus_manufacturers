Spree::Product.class_eval do
  has_one :spree_manufacturer, :class_name => 'Spree::Manufacturer'
end