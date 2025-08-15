class TerminalModel < ApplicationRecord
  audited

  belongs_to :terminal_manufacturer

  validates :name, presence: true
end
