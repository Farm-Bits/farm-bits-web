class Terminal < ApplicationRecord
  audited

  belongs_to :terminal_model
  belongs_to :site, optional: true
  belongs_to :client, optional: true

  encrypts :username
  encrypts :password

  has_many :plcs, dependent: :nullify
  accepts_nested_attributes_for :plcs, :allow_destroy => true

  validates :label, presence: true
  validates :name, presence: true
  validates :imei, presence: true, uniqueness: { case_sensitive: false }
  validates :serial_number, presence: true, uniqueness: { case_sensitive: false }
  validates :iccid, presence: true, uniqueness: { case_sensitive: false }
  validates :phone_number, presence: true, uniqueness: { case_sensitive: false }

  def plc_assignments=(plc_assignments_params)
    ActiveRecord::Base.transaction do
      plcs.update_all(terminal_id: nil)

      plc_assignments_params.each do |assignment|
        plc = Plc.find(assignment[:id])
        plc.update!(assignment.merge(terminal_id: id))
      end
    end
  end
end
