class InterfaceRegisterMapping < ApplicationRecord
  audited

  belongs_to :interface
  belongs_to :register_template

  # validates :category, uniqueness: {
  #   scope: :interface_id,
  #   message: ->(object, data) {
  #       "mapping for '#{data[:value]}' already exists for interface '#{object.interface&.name}'"
  #     }
  #   }, if: -> {
  #     category.in?(MeasurementSubtype::DATA_CATEGORIES)
  #   }
  validate :register_template_has_interface_category
  validate :register_template_belongs_to_same_plc_version

  private
    def register_template_has_interface_category
      if !register_template.present?
        return
      end

      if !register_template.category.in?(Interface::CATEGORIES)
        errors.add(
          :register_template,
          "must have an interface category (#{Interface::CATEGORIES.join(', ')}), " \
          "got '#{register_template.category}'"
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
