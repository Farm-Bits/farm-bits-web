class InterfaceRegisterMapping < ApplicationRecord
  audited

  belongs_to :interface
  belongs_to :register_template

  validates :data_category, presence: true, inclusion: { in: MeasurementSubtype::DATA_CATEGORIES }
  validates :data_category, uniqueness: { scope: :interface_id }
  validate :register_template_category_matches_data_category
  validate :register_template_belongs_to_same_plc_version

  private
    def register_template_category_matches_data_category
      if !register_template.present?
        return
      end

      if register_template.category != data_category
        errors.add(
          :register_template,
          "category '#{register_template.category}' must match data_category '#{data_category}'"
        )
      end
    end

    def register_template_belongs_to_same_plc_version
      if !interface.present? || !register_template.present?
        return
      end

      if interface.plc_version_id != register_template.plc_version_id
        errors.add(:register_template, 'must belong to the same PLC version as the interface')
      end
    end
end
