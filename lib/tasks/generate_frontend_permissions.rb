#!/usr/bin/env ruby

# Script to generate TypeScript types and permissions for frontend
# Usage: rails runner lib/tasks/generate_frontend_permissions.rb
# Or: bundle exec rails runner lib/tasks/generate_frontend_permissions.rb

require 'fileutils'

class FrontendPermissionsGenerator
  FRONTEND_TYPES_PATH = Rails.root.join('app/frontend/types/permissions.ts')

  def initialize
    @routes = extract_routes_from_rails
  end

  def generate
    generate_typescript_types
  end

  private
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

    def generate_typescript_types
      FileUtils.mkdir_p(File.dirname(FRONTEND_TYPES_PATH))

      role_values = Roleable::ROLE_IDS.keys.map { |v| "'#{v}'" }.join(' | ')
      role_constants = Roleable::ROLES.map do |key, value|
        "  #{key}: {
    name: '#{value[:name]}',
    description: '#{value[:description]}'
  }"
      end.join(",\n")

      controller_keys = @routes.map { |r| r[:controller] }.uniq.map { |c| "'#{c.gsub('/', '_')}'" }.join(' | ')

      content = <<~TYPESCRIPT
        // Auto-generated file - Do not edit manually
        // Generated at: #{Time.current}

        // Available roles from Roleable
        export type Role = #{role_values};

        export const ROLES = {
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
          role: Role;
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
end

if defined?(Rails) && Rails.application
  generator = FrontendPermissionsGenerator.new
  generator.generate
else
  puts "❌ This script must be run in a Rails environment"
  puts "💡 Try: rails runner lib/tasks/generate_frontend_permissions.rb"
end