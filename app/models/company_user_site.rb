class CompanyUserSite < ApplicationRecord
  audited

  belongs_to :company_user
  belongs_to :site

  validates :company_user_id, uniqueness: { scope: :site_id }
  validates :site_id, uniqueness: { scope: :company_user_id }
  validate :site_belongs_to_company_user_company

  private
    def site_belongs_to_company_user_company
      if site.company_id != company_user.company_id
        errors.add(:site, 'must belong to the same company as the company_user')
      end
    end
end
