class SiteSunData < ApplicationRecord
  self.table_name = 'site_sun_data'

  belongs_to :site

  validates :date, presence: true, uniqueness: { scope: :site_id }
  validates :sunrise, presence: true
  validates :sunset, presence: true
  validate :sunrise_before_sunset

  private
    def sunrise_before_sunset
      if sunrise.present? && sunset.present? && sunrise >= sunset
        errors.add(:sunrise, 'must be before sunset')
      end
    end
end
