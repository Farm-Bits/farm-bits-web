class TerminalManufacturer < ApplicationRecord
  audited

  has_many :terminal_models, dependent: :destroy
  accepts_nested_attributes_for :terminal_models, :allow_destroy => true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
