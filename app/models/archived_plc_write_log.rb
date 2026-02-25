class ArchivedPlcWriteLog < ApplicationRecord
  belongs_to :measurement_point
  belongs_to :plc
  belongs_to :site
  belongs_to :user
  belongs_to :register_template
end
