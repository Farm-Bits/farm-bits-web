class Site < ApplicationRecord
  audited

  belongs_to :company

  has_many :company_user_sites, dependent: :destroy
  accepts_nested_attributes_for :company_user_sites
  has_many :company_users, through: :company_user_sites

  has_many :terminals

  has_many :plcs

  has_many :segments, dependent: :destroy
  accepts_nested_attributes_for :segments, allow_destroy: true

  has_many :measurement_points

  validates :name, presence: true
  validates :country, presence: true
  validates :time_zone, presence: true, inclusion: { in: TZInfo::Timezone.all.map(&:identifier) }
  validate :country_must_be_valid
  validate :city_must_be_valid_if_present
  validate :coordinates_must_be_present_together
  validates :latitude, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90
  }, allow_blank: true
  validates :longitude, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180
  }, allow_blank: true
  validates :altitude, numericality: {
    greater_than_or_equal_to: -431,
    less_than_or_equal_to: 8849
  }, allow_blank: true

  before_validation :set_default_name, if: -> { name.blank? && company.present? }
  before_validation :set_default_time_zone
  before_destroy :prevent_destroy_last_site
  before_destroy :prevent_destroy_connected_site

  def time_zone_object
    ActiveSupport::TimeZone[time_zone]
  end

  private
    def country_must_be_valid
      if country.present?
        service = GoogleMapsService.new
        if !service.valid_country?(country)
          errors.add(:country, 'is not a valid country')
        end
      end
    end

    def city_must_be_valid_if_present
      if city.present? && country.present?
        service = GoogleMapsService.new
        if !service.valid_city?(city, country)
          errors.add(:city, 'is not a valid city in the specified country')
        end
      end
    end

    def coordinates_must_be_present_together
      coordinates = [latitude, longitude]
      if coordinates.any?(&:present?) && coordinates.any?(&:blank?)
        errors.add(:base, 'Latitude and longitude must both be present if one is provided')
      end
    end

    def set_default_name
      other_sites = company.sites.to_a.select { |p| p != self && !p.marked_for_destruction? }

      if other_sites.empty?
        self.name = 'My First Site'
      end
    end

    def infer_time_zone
      service = GoogleMapsService.new

      if latitude.present? && longitude.present?
        return service.time_zone_for_coordinates(latitude, longitude)
      end

      if city.present? && country.present?
        coords = service.geocode_country("#{city}, #{country}")
        if coords
          return service.time_zone_for_coordinates(coords[:latitude], coords[:longitude])
        end
      end

      if country.present?
        coords = service.geocode_country(country)
        if coords
          return service.time_zone_for_coordinates(coords[:latitude], coords[:longitude])
        end
      end

      nil
    end

    def set_default_time_zone
      if time_zone.present?
        return
      end

      inferred = infer_time_zone
      if inferred
        self.time_zone = inferred
      end

      self.time_zone ||= 'UTC'
    end

    def prevent_destroy_last_site
      if company.sites.count <= 1
        errors.add(:base, 'Cannot delete the last site for a company')
        throw(:abort)
      end
    end

    def prevent_destroy_connected_site
      if terminals.any? || plcs.any? || measurement_points.any?
        errors.add(:base, 'Cannot delete site with connected measurement points or terminals')
        throw(:abort)
      end
    end
end
