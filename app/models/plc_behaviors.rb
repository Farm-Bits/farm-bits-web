# Resolver for PLC behavior profiles.
#
# Each PlcVersion has a `behavior_profile` string that maps to a
# behavior class. The class defines what the backend can do with
# that PLC version.
#
# Usage:
#   behavior = PlcBehaviors.for(plc)
#   behavior.sync_clock!          # runs or no-ops based on version
#   behavior.sync_io_active!      # same
#
module PlcBehaviors
  REGISTRY = {
    'standard_v1' => 'PlcBehaviors::StandardV1'
  }.freeze

  def self.for(plc)
    profile = plc.plc_version&.behavior_profile
    if !profile.present?
      return PlcBehaviors::Base.new(plc)
    end

    class_name = REGISTRY[profile]

    if !class_name.present?
      Rails.logger.warn(
        "[PlcBehaviors] Unknown profile '#{profile}' for PlcVersion #{plc.plc_version_id}"
      )
      return PlcBehaviors::Base.new(plc)
    end

    class_name.constantize.new(plc)
  end

  def self.registered_profiles
    REGISTRY.keys
  end

  def self.class_for(profile)
    class_name = REGISTRY[profile]
    class_name&.constantize
  end
end
