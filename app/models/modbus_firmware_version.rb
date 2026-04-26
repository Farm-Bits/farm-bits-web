class ModbusFirmwareVersion < ApplicationRecord
  audited

  belongs_to :model

  has_one :manufacturer, through: :model

  has_many :interfaces, dependent: :destroy
  accepts_nested_attributes_for :interfaces, :allow_destroy => true

  has_many :register_templates, dependent: :destroy
  accepts_nested_attributes_for :register_templates, :allow_destroy => true

  has_many :plcs, dependent: :restrict_with_error

  has_many :modbus_devices, dependent: :restrict_with_error

  has_many :modbus_firmware_compatibilities_as_host, class_name: 'ModbusFirmwareCompatibility', foreign_key: :host_version_id, dependent: :destroy
  has_many :supported_peripheral_versions, through: :modbus_firmware_compatibilities_as_host, source: :peripheral_version

  has_many :modbus_firmware_compatibilities_as_peripheral, class_name: 'ModbusFirmwareCompatibility', foreign_key: :peripheral_version_id, dependent: :destroy
  has_many :supporting_host_versions, through: :modbus_firmware_compatibilities_as_peripheral, source: :host_version

  validates :name, presence: true, uniqueness: { scope: :model_id }
  validates :version_code, presence: true, uniqueness: { scope: :model_id }
  validate :relay_layout_all_or_none
  validates :relay_slot_base, :relay_slot_size, :relay_max_slots, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :relay_register_type, inclusion: { in: RegisterTemplate::REGISTER_TYPES }, allow_nil: true
  validate :only_one_latest_per_model, if: :is_latest?

  after_save :ensure_single_latest, if: :saved_change_to_is_latest?

  def full_name
    "#{model.full_name} v#{version_code}"
  end

  def host_capable?
    relay_slot_base.present? && relay_slot_size.present? && relay_max_slots.present? && relay_register_type.present?
  end

  def copy_registers_from(source_version)
    source_version.register_templates.find_each do |template|
      register_templates.create!(
        template.attributes.except('id', 'modbus_firmware_version_id', 'created_at', 'updated_at')
      )
    end
  end

  private
    def relay_layout_all_or_none
      fields = [relay_slot_base, relay_slot_size, relay_max_slots, relay_register_type]
      present_count = fields.count(&:present?)
      if present_count == 0 || present_count == 4
        return
      end

      errors.add(:base, "relay_slot_base, relay_slot_size, relay_max_slots, and relay_register_type must all be set together, or all left blank")
    end

    def only_one_latest_per_model
      existing_latest = model.modbus_firmware_versions.where(is_latest: true).where.not(id: id)
      if existing_latest.exists?
        errors.add(:is_latest, 'can only be set for one version per model')
      end
    end

    def ensure_single_latest
      if !is_latest?
        return
      end

      model.modbus_firmware_versions.where(is_latest: true).where.not(id: id).update_all(is_latest: false)
    end
end
