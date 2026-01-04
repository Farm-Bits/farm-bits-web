class Site < ApplicationRecord
  audited

  belongs_to :client

  has_many :site_users, dependent: :destroy
  accepts_nested_attributes_for :site_users

  has_many :users, through: :site_users

  has_many :terminals, dependent: :destroy

  has_many :segments, dependent: :destroy

  has_many :measurement_points, dependent: :destroy

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

  before_validation :set_default_name, if: -> { name.blank? && client.present? }
  before_validation :set_default_time_zone

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
        unless service.valid_city?(city, country)
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
      other_sites = client.sites.to_a.select { |p| p != self && !p.marked_for_destruction? }

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
      inferred = infer_time_zone
      self.time_zone = inferred if inferred

      self.time_zone ||= 'UTC'
    end
end
