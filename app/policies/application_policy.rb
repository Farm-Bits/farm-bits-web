# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class << self
    def controller_mappings
      @controller_mappings ||= {}
    end

    def maps_to_controller(controller_name, actions: {})
      controller_mappings[controller_name] = actions
      clear_discovery_cache!
    end

    def discover_all_policies
      if @all_policies
        return @all_policies
      end

      @all_policies = Rails.cache.fetch('policy_discovery/all_policies') do
        policy_files = Dir.glob(Rails.root.join('app/policies/**/*_policy.rb'))
        policy_files.each { |file| require file }

        ObjectSpace.each_object(Class).select do |klass|
          klass < ApplicationPolicy &&
          klass != ApplicationPolicy &&
          klass.respond_to?(:controller_mappings)
        rescue
          false
        end
      end
    end

    private
      def clear_discovery_cache!
        @all_policies = nil
        if defined?(Rails.cache)
          Rails.cache.delete('policy_discovery/all_policies')
        end
      end
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private
      attr_reader :user, :scope
  end

  protected
    def client_user
      if !current_client || !user
        return nil
      end

      @client_user ||= user.client_user_for(current_client)
    end

    def current_client
      if user.respond_to?(:instance_variable_get)
        @current_client ||= user.instance_variable_get(:@current_client)
      end
    end
end
