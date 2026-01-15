class Segment < ApplicationRecord
  audited

  belongs_to :site
  belongs_to :client

  has_many :measurement_points, dependent: :destroy

  validates :name, presence: true
  validate :client_matches_site_client

  before_destroy :prevent_destroy_connected_site

  private
    def client_matches_site_client
      if site.client_id != client_id
        errors.add(:client, 'must match the site client')
      end
    end

    def prevent_destroy_connected_site
      if measurement_points.any?
        errors.add(:base, 'Cannot delete segment with connected measurement points')
        throw(:abort)
      end
    end
end
