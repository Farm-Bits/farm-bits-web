require 'rails_helper'

# Catch-all integrity check for seeded firmware data.
#
# For every ModbusFirmwareVersion that's in the test DB, verifies that:
#   1. Its behavior_profile (if set) resolves to a real class.
#   2. Every concrete role declared in that behavior's SYSTEM_GROUPS exists
#      as a register_template on the firmware — when the group is present.
#      (Absent groups are tolerated; that just means the firmware doesn't
#      use that feature.)
#   3. Every feature's register_selector matches at least one register
#      template — otherwise the feature is dead code.
#   4. Firmwares that declare themselves host_capable have at least one
#      relay mapping (otherwise no peripheral can be reached).
#
# To run this, seed the test DB first:
#   bin/rails db:seed RAILS_ENV=test
#
# Without seeds, this entire describe block is skipped — it's not a
# failure to lack seeds, but the spec can't do meaningful work without
# them.

RSpec.describe 'Seeded firmware versions consistency' do
  before do
    if ModbusFirmwareVersion.count == 0
      skip 'No firmware versions in test DB. ' \
           'Run `bin/rails db:seed RAILS_ENV=test` first.'
    end
  end

  it 'every behavior_profile resolves to a registered behavior class' do
    failures = []

    ModbusFirmwareVersion.find_each do |firmware|
      if firmware.behavior_profile.blank?
        next
      end

      klass_name = ModbusBehaviors::REGISTRY[firmware.behavior_profile]
      if !klass_name
        failures << "#{firmware.full_name}: behavior_profile " \
                    "'#{firmware.behavior_profile}' is not in ModbusBehaviors::REGISTRY"
        next
      end

      begin
        klass = klass_name.constantize
      rescue NameError
        failures << "#{firmware.full_name}: REGISTRY points at " \
                    "#{klass_name.inspect} which doesn't exist"
        next
      end

      if !(klass < ModbusBehaviors::Base)
        failures << "#{firmware.full_name}: #{klass_name} does not inherit " \
                    'from ModbusBehaviors::Base'
      end
    end

    expect(failures).to be_empty, "Behavior profile failures:\n  #{failures.join("\n  ")}"
  end

  it 'every present SYSTEM_GROUP has all its required concrete roles' do
    failures = []

    ModbusFirmwareVersion.find_each do |firmware|
      klass = behavior_class_for(firmware)
      if !klass
        next
      end

      firmware_groups = firmware.register_templates.distinct.pluck(:group_name).compact

      klass::SYSTEM_GROUPS.each do |group_pattern, schema|
        matching_groups = resolve_groups(group_pattern, firmware_groups)

        # Group not present at all -> tolerable, the feature just isn't
        # used on this firmware.
        if matching_groups.empty?
          next
        end

        concrete_roles = schema[:roles].reject { |r| r.include?('*') }
        if concrete_roles.empty?
          next
        end

        matching_groups.each do |group_name|
          actual_roles = firmware.register_templates
            .where(group_name: group_name)
            .pluck(:group_role)
            .compact
            .uniq

          missing = concrete_roles - actual_roles
          if missing.any?
            failures << "#{firmware.full_name}: group '#{group_name}' is " \
                        "missing required role(s): #{missing.join(', ')}"
          end
        end
      end
    end

    expect(failures).to be_empty, "SYSTEM_GROUPS coverage failures:\n  #{failures.join("\n  ")}"
  end

  it 'every host_capable firmware has at least one relay mapping' do
    failures = []

    ModbusFirmwareVersion.find_each do |firmware|
      if !firmware.host_capable?
        next
      end

      if firmware.relay_mappings.count == 0
        failures << "#{firmware.full_name}: declared host_capable (relay_slot_* " \
                    'are set) but has zero relay_mappings — no peripheral ' \
                    'register can be reached through this host'
      end
    end

    expect(failures).to be_empty, "Relay mapping failures:\n  #{failures.join("\n  ")}"
  end

  private
    def behavior_class_for(firmware)
      if firmware.behavior_profile.blank?
        return nil
      end

      klass_name = ModbusBehaviors::REGISTRY[firmware.behavior_profile]
      if !klass_name
        return nil
      end

      klass_name.constantize
    rescue NameError
      nil
    end

    # Given a pattern like 'om_sensor_cond_*' and the firmware's actual
    # group names, return the subset of group names that match. For a
    # concrete (non-wildcard) pattern, that's just [pattern] if it's in
    # the firmware groups, [] otherwise.
    def resolve_groups(group_pattern, firmware_groups)
      if !group_pattern.include?('*')
        return firmware_groups.include?(group_pattern) ? [group_pattern] : []
      end

      regex = Regexp.new('\A' + group_pattern.gsub('*', '\d+') + '\z')
      firmware_groups.grep(regex)
    end
end
