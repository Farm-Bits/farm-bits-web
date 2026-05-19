class ChangeIccidToNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :gateways, :iccid, true
    change_column_null :gateways, :phone_number, true
  end
end
