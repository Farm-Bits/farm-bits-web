class PlcVersion < ApplicationRecord
  audited

  belongs_to :model

  has_one :manufacturer, through: :model

  has_many :interfaces, dependent: :destroy
  accepts_nested_attributes_for :interfaces, :allow_destroy => true

  has_many :register_templates, dependent: :destroy
  accepts_nested_attributes_for :register_templates, :allow_destroy => true

  has_many :plcs, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :model_id }
  validates :version_code, presence: true, uniqueness: { scope: :model_id }
  validate :only_one_latest_per_model, if: :is_latest?

  after_save :ensure_single_latest, if: :saved_change_to_is_latest?

  def full_name
    "#{model.full_name} v#{version_code}"
  end

  def copy_registers_from(source_version)
    source_version.register_templates.find_each do |template|
      register_templates.create!(
        template.attributes.except('id', 'plc_version_id', 'created_at', 'updated_at')
      )
    end
  end

  private
    def only_one_latest_per_model
      existing_latest = model.plc_versions.where(is_latest: true).where.not(id: id)
      if existing_latest.exists?
        errors.add(:is_latest, 'can only be set for one version per model')
      end
    end

    def ensure_single_latest
      if !is_latest?
        return
      end

      model.plc_versions.where(is_latest: true).where.not(id: id).update_all(is_latest: false)
    end
end
