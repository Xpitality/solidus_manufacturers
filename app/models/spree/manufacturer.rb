module Spree
  class Manufacturer < Spree::Base
    extend FriendlyId
    friendly_id :slug_candidates, use: :history

    # solidus_globalize
    translates :name, :slug, :description, :abstract, :meta_title, :meta_description, :meta_keywords,
               fallbacks_for_empty_translations: true
    include SolidusGlobalize::Translatable


    has_many :images, -> { order(:position) }, class_name: 'Spree::ManufacturerImage', as: :viewable, dependent: :destroy

    belongs_to :country, class_name: "Spree::Country"
    belongs_to :state, class_name: "Spree::State"

    validates :meta_keywords, length: { maximum: 255 }
    validates :meta_title, length: { maximum: 255 }
    validates :name, presence: true
    validates :slug, length: { minimum: 3 }, uniqueness: { allow_blank: true }
    validate :state_validate, :postal_code_validate

    self.whitelisted_ransackable_associations = %w[stores images]
    self.whitelisted_ransackable_attributes = %w[slug]


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
  end
end