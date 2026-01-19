# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :current_user, :current_client, :current_client_user, :current_site, :record

  def initialize(context, record)
    @current_user = context[:current_user]
    @current_client = context[:current_client]
    @current_client_user = context[:current_client_user]
    @current_site = context[:current_site]
    @record = record
  end

  Roleable::ROLE_IDS.each_key do |role_key|
    define_method "#{role_key}?" do
      current_client_user&.send("#{role_key}?")
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def new?
    create?
  end

  def update?
    admin?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  class Scope
    attr_reader :current_user, :current_client, :current_client_user, :current_site, :scope

    def initialize(context, scope)
      @context = context
      @scope = scope

      @current_user = context[:current_user]
      @current_client = context[:current_client]
      @current_client_user = context[:current_client_user]
      @current_site = context[:current_site]
    end

    def policy_scope!(scope)
      Pundit.policy_scope!(@context, scope)
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end
end
