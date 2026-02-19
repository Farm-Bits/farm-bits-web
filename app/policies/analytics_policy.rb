class AnalyticsPolicy < ApplicationPolicy
  def show?
    true
  end

  def hourly?
    true
  end

  def raw?
    true
  end
end
