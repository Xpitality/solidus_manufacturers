module Spree
  class Manufacturer < Spree::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :history

    # solidus_globalize
    translates :name, :slug, :description, :abstract, :why_we_like_it, :meta_title, :meta_description, :meta_keywords,
               fallbacks_for_empty_translations: true
    include SolidusGlobalize::Translatable


    has_many :images, -> { order(:position) }, class_name: 'Spree::ManufacturerImage', as: :viewable, dependent: :destroy
    has_many :products, class_name: 'Spree::Product'

    belongs_to :country, class_name: 'Spree::Country'
    belongs_to :state, class_name: 'Spree::State'

    belongs_to :taxon, class_name: 'Spree::Taxon'

    validates :meta_keywords, length: { maximum: 255 }
    validates :meta_title, length: { maximum: 255 }
    validates :name, presence: true
    validates :slug, length: { minimum: 3 }, uniqueness: { allow_blank: true }
    validate :state_validate, :postal_code_validate

    self.whitelisted_ransackable_associations = %w[stores images]
    self.whitelisted_ransackable_attributes = %w[slug]

    after_create :update_associated_taxons
    after_update :update_associated_taxons

    def find_or_create_country_taxon
      country_name_it = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :it)
      country_name_en = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :en)

      if self.country && self.state
        country_taxon_translation = Spree::Taxon::Translation.where(locale: :it, permalink: "vino/nazione/#{country_name_it.parameterize}").first
        if country_taxon_translation
          Spree::Taxon.find(country_taxon_translation.spree_taxon_id)
        else
          create_country_taxon(country_name_it, country_name_en)
        end
      end
    end

    def find_or_create_region_taxon(country_taxon)
      country_name_it = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :it)
      country_name_en = Spree.t(self.country.iso, scope: 'country_names', default: self.country.name, locale: :en)

      if self.country && self.state
        region_taxon_translation = Spree::Taxon::Translation.where(locale: :it, permalink: "vino/nazione/#{country_name_it.parameterize}/#{self.state.name.parameterize}").first
        if region_taxon_translation
          Spree::Taxon.find(region_taxon_translation.spree_taxon_id)
        else
          create_region_taxon(country_name_it, country_name_en, country_taxon)
        end
      end
    end

    def display_image
      images.first || Spree::ManufacturerImage.new
    end

    def micro_regions
      unless @micro_regions
        @micro_regions = {}
        row = 0
        File.foreach("#{Rails.root}/db/seeds/micro_regions.csv") do |line|
          if row == 0
            row +=1
          else
            r = line.split(',')
            country_name = r[1].gsub("\n", '')
            @micro_regions[country_name] ||= []
            @micro_regions[country_name] << r[0]
          end
        end
      end

      if self.country && self.country.name && @micro_regions[self.country.name]
        country_name = self.country.name
        @micro_regions[country_name].map{|r| [r, I18n.t("micro_regions.#{country_name.parameterize.underscore}.#{r}.name", default: r)] }

      else
        a = []
        @micro_regions.each do |country_name, regions|
          regions.each do |r|
            a << [r, "#{country_name} > #{I18n.t("micro_regions.#{country_name.parameterize.underscore}.#{r}.name", default: r)}"]
          end
        end
        a
      end
    end


    private

    def state_validate
      # Skip state validation without country (also required)
      # or when disabled by preference
      return if country.blank? || !Spree::Config[:address_requires_state]
      return unless country.states_required

      # ensure associated state belongs to country
      if state.present?
        if state.country == country
          self.state_name = nil # not required as we have a valid state and country combo
        elsif state_name.present?
          self.state = nil
        else
          errors.add(:state, :invalid)
        end
      end

      # ensure state_name belongs to country without states, or that it matches a predefined state name/abbr
      if state_name.present?
        if country.states.present?
          states = country.states.find_all_by_name_or_abbr(state_name)

          if states.size == 1
            self.state = states.first
            self.state_name = nil
          else
            errors.add(:state, :invalid)
          end
        end
      end

      # ensure at least one state field is populated
      errors.add :state, :blank if state.blank? && state_name.blank?
    end

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

    def update_associated_taxons
      if self.country && self.state
        country_taxon = find_or_create_country_taxon
        find_or_create_region_taxon(country_taxon)
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

    def create_region_taxon(country_name_it, country_name_en, country_taxon)
      Spree::Taxon.create!(
        {
          parent_id: country_taxon.id,
          position: 0,
          name: self.state.name,
          permalink: "vino/nazione/#{country_name_it.parameterize}/#{self.state.name}/#{self.state.name.parameterize}",
          taxonomy_id: 1,
          translations: [
            Spree::Taxon::Translation.new({ locale: :it, name: self.state.name, description: self.state.name, meta_title: self.state.name, meta_description: self.state.name, meta_keywords: self.state.name, permalink: "vino/nazione/#{country_name_it.parameterize}/#{self.state.name.parameterize}" }),
            Spree::Taxon::Translation.new({ locale: :en, name: self.state.name, description: self.state.name, meta_title: self.state.name, meta_description: self.state.name, meta_keywords: self.state.name, permalink: "wine/country/#{country_name_en.parameterize}/#{self.state.name.parameterize}" })
          ]
        })
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