class Plc < ApplicationRecord
  audited

  belongs_to :model
  belongs_to :plc_version
  belongs_to :terminal, optional: true
  belongs_to :site, optional: true
  belongs_to :client, optional: true

  encrypts :username
  encrypts :password
  encrypts :web_username
  encrypts :web_password

  has_many :measurement_points, dependent: :destroy

  validates :label, presence: true
  validates :name, presence: true
  validates :serial_number, presence: true, uniqueness: true
  validates :slave,
    presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 247,
      message: 'must be between 1 and 247 (Modbus specification)'
    }
  validates :private_ip, format: {
    with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/
  }
  validates :private_ip, uniqueness: {
    scope: :terminal_id,
    message: 'is already assigned to another PLC on this terminal',
    conditions: -> { where.not(terminal_id: nil) }
  }, if: -> { terminal_id.present? }
  validates :username, presence: true
  validates :password, presence: true
  validates :web_username, presence: true
  validates :web_password, presence: true
  validate :model_is_plc_type
  validate :plc_version_belongs_to_model
  validate :client_matches_site_client

  after_create :create_measurement_points_from_templates
  after_create :authorize_ingestion_email
  after_update :sync_measurement_points_client
  after_update :update_ingestion_email_status, if: :should_update_ingestion_email?
  after_destroy :revoke_ingestion_email

  def touch_last_seen!(timestamp = Time.current)
    update_column(:last_seen_at, timestamp)
  end

  private
    def model_is_plc_type
      if !model.present?
        return
      end

      if model.device_type != 'plc'
        errors.add(:model, 'must be a PLC model')
      end
    end

    def plc_version_belongs_to_model
      if !model.present? || !plc_version.present?
        return
      end

      if plc_version.model_id != model_id
        errors.add(:plc_version, "must belong to the selected model (#{model.full_name})")
      end
    end

    def client_matches_site_client
      if site.present? && site.client_id != client_id
        errors.add(:client, 'must match the client of the assigned site')
      end

      if terminal.present? && terminal.client_id != client_id
        errors.add(:client, 'must match the client of the assigned terminal')
      end
    end

    def create_measurement_points_from_templates
      if !plc_version.present?
        return
      end

      plc_version.register_templates.find_each do |template|
        measurement_points.create!(
          name: template.name,
          description: template.description,
          position: template.position,
          active: true,
          measurement_subtype: nil,
          register_template: template,
          site: nil,
          client: client
        )
      end
    end

    def authorize_ingestion_email
      if username.blank?
        return
      end

      SyncPlcIngestionEmailJob.perform_later(id, 'create')
    rescue PlcIngestionClient::Error => e
      Rails.logger.error "Failed to authorize PLC email #{username}: #{e.message}"
    end

    def sync_measurement_points_client
      update_attrs = {}
      if saved_change_to_site_id?
        update_attrs[:site_id] = site_id
      end

      if saved_change_to_client_id?
        update_attrs[:client_id] = client_id
      end

      if !update_attrs.empty?
        measurement_points.update_all(update_attrs)
      end
    end

    def should_update_ingestion_email?
      saved_change_to_username? ||
        (respond_to?(:saved_change_to_active?) && saved_change_to_active?)
    end

    def update_ingestion_email_status
      if username.blank?
        return
      end

      SyncPlcIngestionEmailJob.perform_later(id, 'update')
    rescue PlcIngestionClient::Error => e
      Rails.logger.error "Failed to update PLC email status #{username}: #{e.message}"
    end

    def revoke_ingestion_email
      if username.blank?
        return
      end

      SyncPlcIngestionEmailJob.perform_later(id, 'destroy')
    rescue PlcIngestionClient::Error => e
      Rails.logger.error "Failed to revoke PLC email #{username}: #{e.message}"
    end
end
