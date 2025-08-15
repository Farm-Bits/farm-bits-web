class InterfaceRegister < ApplicationRecord
  audited

  belongs_to :interface
  belongs_to :register
end
