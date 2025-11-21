#!/usr/bin/env ruby

# Script to generate TypeScript types and permissions for frontend
# Usage: rails runner lib/tasks/generate_frontend_permissions.rb
# Or: bundle exec rails runner lib/tasks/generate_frontend_permissions.rb

require 'fileutils'

class FrontendPermissionsGenerator
  FRONTEND_TYPES_PATH = Rails.root.join('app/frontend/types/permissions.ts')
  FRONTEND_UTILS_PATH = Rails.root.join('app/frontend/utils/permissions.ts')

  def initialize
    @roles = Roleable::ROLES
    @policies = discover_policies
    @routes = extract_routes_from_rails
  end

  def generate
    puts "🚀 Generating frontend permissions..."
    puts "📋 Found roles: #{@roles.keys.join(', ')}"
    puts "🔒 Found policies: #{@policies.map(&:name).join(', ')}"
    puts "🛣️  Found #{@routes.count} user area routes"

    generate_typescript_types
    generate_permission_utils

    puts "✅ Generated frontend permissions successfully!"
    puts "📁 Types: #{FRONTEND_TYPES_PATH}"
    puts "📁 Utils: #{FRONTEND_UTILS_PATH}"
  end

  private
    def discover_policies
      @policies_with_mappings ||= ApplicationPolicy.discover_all_policies.select do |policy_class|
        policy_class.controller_mappings.any?
      end
    end

    def extract_routes_from_rails
      routes = []

      Rails.application.routes.routes.each do |route|
        if !route.defaults[:controller] || !route.defaults[:controller].start_with?('user_area/')
          next
        end

        controller_name = route.defaults[:controller].gsub('user_area/', '')
        action_name = route.defaults[:action]

        if !action_name
          next
        end

        route_info = {
          controller: controller_name,
          action: action_name,
          path: route.path.spec.to_s.gsub(/\(\.:format\)$/, ''),
          verb: route.verb
        }

        routes << route_info
      end

      routes.uniq { |r| [r[:controller], r[:action]] }
    end

    def policy_methods_for_class(policy_class)
      policy_methods = []

      policy_class.instance_methods.each do |method|
        if !method.to_s.end_with?('?')
          next
        end

        defining_class = policy_class.instance_method(method).owner

        if defining_class == policy_class ||
          (defined?(ApplicationPolicy) && defining_class == ApplicationPolicy) ||
          defining_class.name&.end_with?('Policy')
          policy_methods << method
        end
      end

      excluded_methods = [
        :is_a?, :nil?, :empty?, :present?, :blank?, :instance_variable_defined?,
        :instance_of?, :kind_of?, :frozen?, :eql?, :respond_to?, :equal?,
        :instance_variable_get?, :instance_variable_set?, :remove_instance_variable?,
        :instance_variables_defined?, :singleton_method_defined?
      ]

      policy_methods.reject { |method| excluded_methods.include?(method) }.uniq
    end

    def model_name_from_policy(policy_class)
      policy_class.name.gsub(/Policy$/, '')
    end

    def generate_typescript_types
      FileUtils.mkdir_p(File.dirname(FRONTEND_TYPES_PATH))

      role_values = @roles.values.map { |v| "'#{v}'" }.join(' | ')
      role_constants = @roles.map { |key, value| "  #{key.upcase}: '#{value}' as const" }.join(",\n")

      controller_keys = @routes.map { |r| r[:controller] }.uniq.map { |c| "'#{c.gsub('/', '_')}'" }.join(' | ')

      content = <<~TYPESCRIPT
        // Auto-generated file - Do not edit manually
        // Generated at: #{Time.current}

        // Available roles from Roleable
        export type UserRole = #{role_values};

        export const USER_ROLES = {
        #{role_constants}
        } as const;

        // Valid controller keys
        export type ControllerKey = #{controller_keys};

        // Route permissions mapping
        export type RoutePermissions = {
        #{generate_route_permissions_interface}
        };

        // Complete permission context
        export type PermissionContext = {
          role: UserRole;
          routePermissions: RoutePermissions;
        };

        // Route information
        export type RouteInfo = {
          controller: string;
          action: string;
          path: string;
          verb: string;
        };

        export const ROUTES: Record<string, RouteInfo> = {
        #{generate_routes_mapping}
        };
      TYPESCRIPT

      File.write(FRONTEND_TYPES_PATH, content)
    end

    def generate_model_permissions_interface
      @policies.map do |policy_class|
        model_name = model_name_from_policy(policy_class)
        methods = policy_methods_for_class(policy_class)

        if methods.empty?
          next
        end

        action = method.to_s.chomp('?')
        route = @routes.find { |r| r[:controller] == model_name && r[:action] == action }
        if !route
          next
        end

        method_types = methods.map { |method| "    #{action}: boolean;" }.join("\n")

        "  #{model_name.downcase}: {\n#{method_types}\n  };"
      end.compact.join("\n")
    end

    def generate_route_permissions_interface
      controllers = @routes.group_by { |route| route[:controller] }

      controllers.map do |controller, routes|
        actions = routes.map { |route| route[:action] }.uniq
        action_types = actions.map { |action| "    #{action}: boolean;" }.join("\n")

        "  #{controller.gsub('/', '_')}: {\n#{action_types}\n  };"
      end.join("\n")
    end

    def generate_routes_mapping
      routes_content = @routes.map do |route|
        key = "#{route[:controller].gsub('/', '_')}_#{route[:action]}"
        <<~ROUTE.strip
          #{key}: {
              controller: '#{route[:controller]}',
              action: '#{route[:action]}',
              path: '#{route[:path]}',
              verb: '#{route[:verb]}'
            }
        ROUTE
      end.join(",\n  ")

      "  #{routes_content}"
    end

    def generate_permission_utils
      FileUtils.mkdir_p(File.dirname(FRONTEND_UTILS_PATH))

      permission_matrix = generate_permission_matrix

      content = <<~TYPESCRIPT
        // Auto-generated file - Do not edit manually
        // Generated at: #{Time.current}

        import type { UserRole, RoutePermissions } from '../types/permissions';

        // Permission matrix generated from actual policy testing
        const PERMISSION_MATRIX: Record<UserRole, RoutePermissions> = #{JSON.pretty_generate(permission_matrix)};

        function isRoutePermissionKey(key: string): key is keyof RoutePermissions {
          for (const userRole in PERMISSION_MATRIX) {
            if (key in PERMISSION_MATRIX[userRole as UserRole]) {
              return true;
            }
          }
          return false;
        }

        function isActionKeyForController(
          controllerKey: keyof RoutePermissions,
          actionKey: string
        ): actionKey is keyof RoutePermissions[typeof controllerKey] {
          const sampleRole = Object.keys(PERMISSION_MATRIX)[0] as UserRole;
          const controllerPermissions = PERMISSION_MATRIX[sampleRole][controllerKey];
          return actionKey in controllerPermissions;
        }

        /**
         * Check if a user with a given role can access a specific controller/action
         * @param userRole - The role of the user
         * @param controller - The controller name (without 'user_area/' prefix)
         * @param action - The action name
         * @returns true if the user can access the action, false otherwise
         */
        export function canAccess(
          userRole: UserRole,
          controller: string,
          action: string
        ): boolean {
          const rolePermissions = PERMISSION_MATRIX[userRole];
          if (!rolePermissions) {
            return false;
          }

          const controllerKey = controller.replace('/', '_');
          if (!isRoutePermissionKey(controllerKey) || !isActionKeyForController(controllerKey, action))
            return false;

          const controllerPermissions = rolePermissions[controllerKey];
          if (!controllerPermissions) {
            return false;
          }

          return controllerPermissions[action] === true;
        }

        /**
         * Get all permissions for a specific role
         * @param userRole - The role of the user
         * @returns The complete RoutePermissions object for the role
         */
        export function getPermissionsForRole(userRole: UserRole): RoutePermissions {
          return PERMISSION_MATRIX[userRole] || {};
        }

        /**
         * Check if a user can perform any action in a controller
         * @param userRole - The role of the user
         * @param controller - The controller name
         * @returns true if the user can access any action in the controller
         */
        export function canAccessController(
          userRole: UserRole,
          controller: string
        ): boolean {
          const rolePermissions = PERMISSION_MATRIX[userRole];
          if (!rolePermissions) {
            return false;
          }

          const controllerKey = controller.replace('/', '_');
          if (!isRoutePermissionKey(controllerKey))
            return false;

          const controllerPermissions = rolePermissions[controllerKey];
          if (!controllerPermissions) {
            return false;
          }

          return Object.values(controllerPermissions).some(permission => permission === true);
        }

        /**
         * Get accessible routes for a specific role
         * @param userRole - The role of the user
         * @returns Array of accessible routes with controller and action
         */
        export function getAccessibleRoutes(userRole: UserRole): Array<{controller: string, action: string}> {
          const rolePermissions = PERMISSION_MATRIX[userRole];
          if (!rolePermissions) {
            return [];
          }

          const accessibleRoutes: Array<{controller: string, action: string}> = [];

          Object.entries(rolePermissions).forEach(([controllerKey, actions]) => {
            const controller = controllerKey.replace('_', '/');
            Object.entries(actions).forEach(([action, allowed]) => {
              if (allowed) {
                accessibleRoutes.push({ controller, action });
              }
            });
          });

          return accessibleRoutes;
        }

        /**
         * Check multiple permissions at once
         * @param userRole - The role of the user
         * @param permissions - Array of {controller, action} to check
         * @returns Object with each permission check result
         */
        export function checkMultiplePermissions(
          userRole: UserRole,
          permissions: Array<{controller: string, action: string}>
        ): Record<string, boolean> {
          const results: Record<string, boolean> = {};

          permissions.forEach(({ controller, action }) => {
            const key = `${controller}:${action}`;
            results[key] = canAccess(userRole, controller, action);
          });

          return results;
        }

        // Export the permission matrix for debugging/inspection
        export const permissionMatrix = PERMISSION_MATRIX;
      TYPESCRIPT

      File.write(FRONTEND_UTILS_PATH, content)
    end

    def generate_permission_matrix
      permission_matrix = {}

      @roles.each do |role_key, role_value|
        permission_matrix[role_value] = test_permissions_for_role(role_value)
      end

      permission_matrix
    end

    def test_permissions_for_role(role)
      permissions = {}

      controllers = @routes.group_by { |route| route[:controller] }

      controllers.each do |controller_name, controller_routes|
        controller_key = controller_name.gsub('/', '_')
        permissions[controller_key] ||= {}

        controller_routes.each do |route|
          policy_class = find_policy_for_controller(controller_name)

          if policy_class
            can_perform = test_policy_permission(policy_class, role, route[:action])
            permissions[controller_key][route[:action]] = can_perform
          else
            permissions[controller_key][route[:action]] = false
          end
        end
      end

      permissions
    end

    def find_policy_for_controller(controller_name)
      @policies.find do |policy_class|
        mappings = policy_class.controller_mappings

        mappings.any? do |mapped_controller, _actions|
          mapped_controller == controller_name ||
          mapped_controller == "user_area/#{controller_name}" ||
          "user_area/#{mapped_controller}" == controller_name
        end
      end
    end

    def test_policy_permission(policy_class, role, action)
      result = false

      ActiveRecord::Base.transaction do
        begin
          test_user = create_test_user_with_role(role)
          test_record = create_test_record_for_policy(policy_class, test_user)

          policy_method = "#{action}?"
          if policy_class.instance_methods.include?(policy_method.to_sym)
            policy = policy_class.new(test_user, test_record)
            result = policy.send(policy_method) rescue false
          else
            mapped_method = map_action_to_policy_method(action)
            if policy_class.instance_methods.include?(mapped_method.to_sym)
              policy = policy_class.new(test_user, test_record)
              result = policy.send(mapped_method) rescue false
            end
          end
        rescue => e
          Rails.logger.debug "Error testing #{policy_class.name}##{action} for role #{role}: #{e.message}"
          result = false
        ensure
          raise ActiveRecord::Rollback
        end
      end

      result
    end

    def create_test_user_with_role(role)
      user = User.new(
        name: "Test User #{role}",
        email: "test_#{SecureRandom.hex(8)}@example.com",
        password: 'TestPassword123!',
        active: true,
        confirmed_at: Time.current
      )
      user.save(validate: false)

      client = Client.new(
        name: "Test Client #{SecureRandom.hex(4)}",
        subdomain: "test-#{SecureRandom.hex(4)}",
        color: '#FF0000',
        active: true
      )
      client.save(validate: false)

      client_user = ClientUser.new(
        user: user,
        client: client,
        role: role,
        active: true
      )
      client_user.save(validate: false)

      user.instance_variable_set(:@current_client, client)

      user
    end

    def create_test_record_for_policy(policy_class, test_user)
      model_name = model_name_from_policy(policy_class)

      model_class = begin
        model_name.constantize
      rescue NameError
        return OpenStruct.new
      end

      client = test_user.instance_variable_get(:@current_client)
      if model_class == User
        return test_user
      end

      if model_class == Client
        return client
      end

      record = model_class.new
      model_class.reflect_on_all_associations.each do |association|
        case association.name
        when :client
          if association.macro == :belongs_to && client
            record.send("#{association.name}=", client)
          end
        when :user, :inviter
          if association.macro == :belongs_to && association.class_name == 'User'
            record.send("#{association.name}=", test_user)
          end
        end
      end

      model_class.validators.each do |validator|
        if validator.is_a?(ActiveRecord::Validations::PresenceValidator)
          validator.attributes.each do |attribute|
            if [:client, :user, :inviter].include?(attribute)
              next
            end

            column = model_class.columns_hash[attribute.to_s]
            if column
              case column.type
              when :string
                record.send("#{attribute}=", "Test #{attribute.to_s.humanize}")
              when :integer
                record.send("#{attribute}=", 1)
              when :datetime
                record.send("#{attribute}=", Time.current)
              when :boolean
                record.send("#{attribute}=", true)
              end
            end
          end
        end
      end

      record.save(validate: false) rescue nil

      if model_class.reflect_on_association(:site_users) && test_user.client_user_for(client)&.role != 'admin'
        site = client.sites.first || Site.create!(
          name: 'Test Site',
          client: client,
          country: 'United States',
          active: true
        )

        if record.is_a?(Site)
          SiteUser.create!(
            site: record,
            user: test_user,
            role: test_user.client_user_for(client).role,
            active: true
          )
        end
      end

      record
    end

    def map_action_to_policy_method(action)
      direct_method = "#{action}?"
      if policy_class.instance_methods.include?(direct_method.to_sym)
        return direct_method
      end

      policy_class.controller_mappings.each do |_controller, action_mappings|
        if action_mappings.is_a?(Hash) && action_mappings[action.to_sym]
          mapped_method = action_mappings[action.to_sym]
          method_name = mapped_method.to_s
          return method_name.end_with?('?') ? method_name : "#{method_name}?"
        end
      end
      restful_method = "#{action}?"
      if policy_class.instance_methods.include?(restful_method.to_sym)
        return restful_method
      end

      if defined?(ApplicationPolicy)
        if ApplicationPolicy.instance_methods.include?(restful_method.to_sym)
          return restful_method
        end
      end

      nil
    end
end

if defined?(Rails) && Rails.application
  generator = FrontendPermissionsGenerator.new
  generator.generate
else
  puts "❌ This script must be run in a Rails environment"
  puts "💡 Try: rails runner lib/tasks/generate_frontend_permissions.rb"
end