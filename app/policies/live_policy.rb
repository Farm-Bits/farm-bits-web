class LivePolicy < ApplicationPolicy
  def show?
    true
  end

  def poll?
    true
  end
end
