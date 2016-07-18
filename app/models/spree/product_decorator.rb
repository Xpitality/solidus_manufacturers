Spree::Product.class_eval do
  belongs_to :manufacturer, :class_name => 'Spree::Manufacturer'
end