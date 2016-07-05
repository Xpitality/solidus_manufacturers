Deface::Override.new(
  virtual_path: 'spree/admin/products/_form',
  name: 'add_manufacturer_select_to_form',
  insert_bottom: '[data-hook="admin_product_form_right"]',
  partial: 'spree/admin/products/manufacturers_select'
)
