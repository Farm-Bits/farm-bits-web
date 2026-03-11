# Diagnostic tool for inspecting PLC version capabilities.
# Reads from PlcBehaviors behavior classes.
# Not used at runtime — for debugging and console inspection only.
#
# Usage:
#   PlcCapability.print_diagnostic(plc_version)
#   PlcCapability.validate(plc_version)
#
class PlcCapability
  class << self
    def behavior_class(plc_version)
      profile = plc_version.behavior_profile
      if !profile.present?
        return PlcBehaviors::Base
      end

      PlcBehaviors.class_for(profile) || PlcBehaviors::Base
    end

    def supported_hooks(plc_version)
      behavior = behavior_class(plc_version).new(nil)
      behavior.supported_hooks
    end

    def validate(plc_version)
      klass = behavior_class(plc_version)
      schema = klass::SYSTEM_GROUPS
      report = {}

      schema.each do |group_key, group_def|
        is_pattern = group_def[:pattern] == true

        if is_pattern
          report[group_key] = validate_pattern_group(plc_version, group_key, group_def[:roles])
        elsif group_def[:role_patterns].present?
          report[group_key] = validate_role_patterns(plc_version, group_key, group_def[:role_patterns])
        elsif group_def[:roles].present?
          report[group_key] = validate_fixed_group(plc_version, group_key, group_def[:roles])
        end
      end

      report
    end

    def print_diagnostic(plc_version)
      klass = behavior_class(plc_version)
      profile = plc_version.behavior_profile || '(none)'

      puts "PlcVersion #{plc_version.id} — #{plc_version.name}"
      puts "Profile: #{profile} → #{klass.name}"
      puts '=' * 60

      puts "\nConcerns:"
      klass.ancestors
        .select { |a| a.name&.start_with?('PlcBehaviors::Concerns::') }
        .each { |c| puts "  • #{c.name.demodulize}" }

      puts "\nHooks:"
      hooks = supported_hooks(plc_version)

      if hooks.empty?
        puts "  (none)"
      else
        hooks.each { |h| puts "  ✓ #{h}" }
      end

      puts "\nRegister groups:"
      validate(plc_version).each do |group_key, info|
        icon = { ok: '✓', incomplete: '⚠', missing: '✗' }[info[:status]]
        count = info[:found_count] ? " (#{info[:found_count]} registers)" : ''
        groups = info[:found_groups] ? " (#{info[:found_groups]} groups)" : ''

        puts "  #{icon} #{group_key}#{count}#{groups}"
        puts "    Missing: #{info[:missing_roles].join(', ')}" if info[:missing_roles]&.any?
        puts "    #{info[:notes]}" if info[:notes]
      end
    end

    private
      def validate_fixed_group(plc_version, group_name, expected_roles)
        actual = RegisterTemplate
          .where(plc_version_id: plc_version.id, group_name: group_name)
          .pluck(:group_role).uniq
        if actual.empty?
          return { status: :missing, missing_roles: expected_roles }
        end

        missing = expected_roles - actual
        { status: missing.empty? ? :ok : :incomplete, found_count: actual.size, missing_roles: missing }
      end

      def validate_pattern_group(plc_version, group_pattern, expected_roles)
        sql_pattern = group_pattern.gsub('*', '%')
        groups = RegisterTemplate
          .where(plc_version_id: plc_version.id)
          .where('group_name LIKE ?', sql_pattern)
          .pluck(:group_name).uniq
        if groups.empty?
          return { status: :missing, found_groups: 0 }
        end

        actual = RegisterTemplate
          .where(plc_version_id: plc_version.id, group_name: groups.first)
          .pluck(:group_role).uniq

        missing = expected_roles.present? ? expected_roles - actual : []
        { status: missing.empty? ? :ok : :incomplete, found_groups: groups.size, missing_roles: missing }
      end

      def validate_role_patterns(plc_version, group_name, patterns)
        actual = RegisterTemplate
          .where(plc_version_id: plc_version.id, group_name: group_name)
          .pluck(:group_role).uniq
        if actual.empty?
          return { status: :missing, notes: "Expected roles matching: #{patterns.join(', ')}" }
        end

        unmatched = patterns.select do |pattern|
          regex = Regexp.new('\A' + pattern.gsub('*', '.*') + '\z')
          actual.none? { |role| role.match?(regex) }
        end

        {
          status: unmatched.empty? ? :ok : :incomplete,
          found_count: actual.size,
          notes: unmatched.any? ? "No roles matching: #{unmatched.join(', ')}" : nil
        }
      end
  end
end
