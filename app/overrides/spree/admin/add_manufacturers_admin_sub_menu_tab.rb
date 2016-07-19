Deface::Override.new(
  virtual_path: 'spree/admin/shared/_menu',
  name: 'add_manufacturers_admin_menu_tab',
  insert_top: '[data-hook="admin_tabs"]',
  partial: 'spree/admin/manufacturers/tab'
)
