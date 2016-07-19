Spree::Product.class_eval do
  belongs_to :manufacturer, :class_name => 'Spree::Manufacturer'

  after_create :update_associated_taxons
  after_update :update_associated_taxons

  private

  def update_associated_taxons
    if self.manufacturer
      taxon_ids = self.taxons.pluck(:id)
      self.taxons << self.manufacturer.taxon unless taxon_ids.include?(self.manufacturer.taxon.id)
      if self.manufacturer.country && self.manufacturer.state
        country_taxon = self.manufacturer.find_or_create_country_taxon
        self.taxons << country_taxon unless taxon_ids.include?(country_taxon.id)
        region_taxon = self.manufacturer.find_or_create_region_taxon(country_taxon)
        self.taxons << region_taxon unless taxon_ids.include?(region_taxon.id)
      end
    end
  end
end