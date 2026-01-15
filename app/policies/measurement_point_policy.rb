class MeasurementPointPolicy < ApplicationPolicy
  def update?
    super && current_client_user&.admin?
  end

  def write?
    case current_client_user&.role
    when 'admin'
      super
    when 'manager'
      super && user_assigned_to_site?
    else
      false
    end
  end

  private
    def user_assigned_to_site?
      current_user.site_users.exists?(site: record, active: true)
    end

  class Scope < Scope
    def resolve
      if current_client_user.admin?
        scope.all
      else
        site_ids = policy_scope!(Site).pluck(:id)
        plc_ids = Plc.where(site_id: site_ids).pluck(:id)
        scope.where(plc_id: plc_ids)
      end
    end
  end
end
