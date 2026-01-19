class Segment < ApplicationRecord
  audited

  belongs_to :site

  has_many :measurement_points, dependent: :destroy

  validates :name, presence: true

  before_destroy :prevent_destroy_connected_site

  private
    def prevent_destroy_connected_site
      if measurement_points.any?
        errors.add(:base, 'Cannot delete segment with connected measurement points')
        throw(:abort)
      end
    end
end
