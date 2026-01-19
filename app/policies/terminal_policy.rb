class TerminalPolicy < ApplicationPolicy
  def index?
    true
  end

  def update?
    admin? || site_admin?
  end

  def destroy?
    admin? || site_admin?
  end

  class Scope < Scope
    def resolve
      scope.where(site: current_site)
    end
  end
end
