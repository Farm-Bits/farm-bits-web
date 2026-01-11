class InterfaceRegisterMapping < ApplicationRecord
  audited

  belongs_to :interface
  belongs_to :register_template

  validates :category, presence: true, inclusion: {
    in: Interface::CATEGORIES,
    message: "the category '%{value}' is not a valid interface category"
  }
  # validates :category, uniqueness: {
  #   scope: :interface_id,
  #   message: ->(object, data) {
  #       "mapping for '#{data[:value]}' already exists for interface '#{object.interface&.name}'"
  #     }
  #   }, if: -> {
  #     category.in?(MeasurementSubtype::DATA_CATEGORIES)
  #   }
  validate :register_template_category_matches_category
  validate :register_template_belongs_to_same_plc_version

  private
    def register_template_category_matches_category
      if !register_template.present?
        return
      end

      if register_template.category != category
        errors.add(
          :register_template,
          "category '#{register_template.category}' must match category '#{category}'"
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
