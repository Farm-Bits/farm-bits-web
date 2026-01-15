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

  def index?
    active_context?
  end

  def show?
    active_context? && record_belongs_to_current_client?
  end

  def create?
    active_context?
  end

  def new?
    create?
  end

  def update?
    active_context? && record_belongs_to_current_client?
  end

  def edit?
    update?
  end

  def destroy?
    active_context? && record_belongs_to_current_client?
  end

  private
    def active_context?
      current_user&.active &&
      current_client&.active &&
      current_client_user&.active
    end

    def record_belongs_to_current_client?
      if record.nil?
        return true
      end

      if record.respond_to?(:client_id)
        record.client_id == current_client&.id
      elsif record.respond_to?(:client)
        record.client == current_client
      else
        true
      end
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
