module Spree
  class Manufacturer < Spree::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :history

    has_many :images, -> { order(:position) }, class_name: 'Spree::ManufacturerImage', as: :viewable, dependent: :destroy
    has_many :products, class_name: 'Spree::Product'

    belongs_to :country, class_name: 'Spree::Country'

    belongs_to :taxon, class_name: 'Spree::Taxon'
    belongs_to :micro_region, class_name: 'Spree::MicroRegion'

    default_scope { order(position: :asc) }

    acts_as_list

    validates :meta_keywords, length: { maximum: 255 }
    validates :meta_title, length: { maximum: 255 }
    validates :name, presence: true
    validates :slug, length: { minimum: 3 }, uniqueness: { allow_blank: true }
    validate :postal_code_validate

    self.whitelisted_ransackable_associations = %w[stores images]
    self.whitelisted_ransackable_attributes = %w[slug]

    after_create :update_associated_taxons
    after_update :update_associated_taxons
    after_update :update_product_taxons

    def find_or_create_country_taxon
      country_name_it = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :it)
      country_name_en = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :en)

      if self.country
        country_taxon_translation = Spree::Taxon::Translation.where(locale: :it, permalink: "vino/nazione/#{country_name_it.parameterize}").first
        if country_taxon_translation
          Spree::Taxon.find(country_taxon_translation.spree_taxon_id)
        else
          create_country_taxon(country_name_it, country_name_en)
        end
      end
    end

    def display_image
      images.first || Spree::ManufacturerImage.new
    end

    def micro_regions
      @micro_regions ||= Spree::MicroRegion.where(country_id: self.country.id).map{ |r| [r.id, r.name] }
    end


    private

    def postal_code_validate
      return if country.blank? || country.iso.blank?
      return if !TwitterCldr::Shared::PostalCodes.territories.include?(country.iso.downcase.to_sym)

      postal_code = TwitterCldr::Shared::PostalCodes.for_territory(country.iso)
      errors.add(:zipcode, :invalid) if !postal_code.valid?(zipcode.to_s)
    end

    def slug_candidates
      [
        :name,
        [:name, :city]
      ]
    end

    def update_product_taxons
      self.products.each{ |p| p.update_associated_taxons }
    end

    def update_associated_taxons
      if self.country
        find_or_create_country_taxon
      end

      create_manufacturer_taxon if self.taxon.nil? && !self.name.blank?
    end

    def create_country_taxon(country_name_it, country_name_en)
      root_country_taxon_translation = Spree::Taxon::Translation.where(locale: :it, permalink: 'vino/nazione').first
      if root_country_taxon_translation
        root_country_taxon = Spree::Taxon.find(root_country_taxon_translation.spree_taxon_id)
      else
        root_country_taxon = Spree::Taxon.create!(
          {
            parent_id: Spree::Taxonomy.first.root.id,
            position: 0,
            name: 'Nazione',
            permalink: 'vino/nazione',
            taxonomy_id: 1,
            translations: [
              Spree::Taxon::Translation.new({ locale: :it, name: 'Nazione', description: 'Nazione', meta_title: 'Nazione', meta_description: 'Nazione', meta_keywords: 'Nazione', permalink: 'vino/nazione' }),
              Spree::Taxon::Translation.new({ locale: :en, name: 'Country', description: 'Country', meta_title: 'Country', meta_description: 'Country', meta_keywords: 'Country', permalink: 'wine/country' })
            ]
          })
      end

      country_taxon_translation = Spree::Taxon::Translation.where(permalink: "vino/nazione/#{country_name_it.parameterize}").first
      unless country_taxon_translation
        Spree::Taxon.create!(
          {
            parent_id: root_country_taxon.id,
            position: 0,
            name: country_name_it,
            permalink: "vino/nazione/#{country_name_it.parameterize}",
            taxonomy_id: 1,
            translations: [
              Spree::Taxon::Translation.new({ locale: :it, name: country_name_it, description: country_name_it, meta_title: country_name_it, meta_description: country_name_it, meta_keywords: country_name_it, permalink: "vino/nazione/#{country_name_it.parameterize}" }),
              Spree::Taxon::Translation.new({ locale: :en, name: country_name_en, description: country_name_en, meta_title: country_name_en, meta_description: country_name_en, meta_keywords: country_name_en, permalink: "wine/country/#{country_name_en.parameterize}" })
            ]
          })
      end
    end

    def create_manufacturer_taxon
      root_manufacturers_taxon_translation = Spree::Taxon::Translation.where(locale: :it, permalink: 'vino/produttore').first
      if root_manufacturers_taxon_translation
        root_manufacturers_taxon = Spree::Taxon.find(root_manufacturers_taxon_translation.spree_taxon_id)

        self.taxon = Spree::Taxon.create!(
          {
            parent_id: root_manufacturers_taxon.id,
            position: 0,
            name: self.name,
            permalink: "vino/produttore/#{self.name.parameterize}",
            taxonomy_id: 1,
            translations: [
              Spree::Taxon::Translation.new({ locale: :it, name: self.name, description: self.name, meta_title: self.name, meta_description: self.name, meta_keywords: self.name, permalink: "vino/produttore/#{self.name.parameterize}" }),
              Spree::Taxon::Translation.new({ locale: :en, name: self.name, description: self.name, meta_title: self.name, meta_description: self.name, meta_keywords: self.name, permalink: "wine/manufacturer/#{self.name.parameterize}" })
            ]
          })
        self.save!
      end
    end
  end
end