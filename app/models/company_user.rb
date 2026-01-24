class CompanyUser < ApplicationRecord
  audited
  include Roleable

  belongs_to :company
  belongs_to :user

  has_many :company_user_sites, dependent: :destroy
  has_many :sites, through: :company_user_sites
  accepts_nested_attributes_for :sites

  validates :company_id, uniqueness: { scope: :user_id }
  validates :user_id, uniqueness: { scope: :company_id }
  validates :role, presence: true

  before_destroy :prevent_destroy_last_admin
  after_destroy :destroy_user_if_orphaned

  enum :role, Roleable::ROLE_IDS

  def last_admin_for_company?
    if !admin?
      return false
    end

    other_admins = company.company_users
      .where.not(id: id)
      .where(role: Roleable::ROLE_IDS[:admin])

    other_admins.empty?
  end

  private
    def prevent_destroy_last_admin
      if last_admin_for_company? && !destroyed_by_association
        errors.add(:base, 'Cannot delete the last admin user')
        throw(:abort)
      end
    end

    def destroy_user_if_orphaned
      if user.company_users.count == 0
        user.destroy
      end
    end
end
