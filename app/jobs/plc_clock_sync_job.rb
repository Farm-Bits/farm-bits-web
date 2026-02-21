class PlcClockSyncJob
  include Sidekiq::Job
  queue_as :critical

  TIME_COMPONENT_MAP = {
    'seconds'      => ->(time) { time.sec },
    'minutes'      => ->(time) { time.min },
    'hours'        => ->(time) { time.hour },
    'day_of_week'  => ->(time) { time.wday },
    'day_of_month' => ->(time) { time.day },
    'month'        => ->(time) { time.month },
    'year'         => ->(time) { time.year % 100 }
  }.freeze
  REQUIRED_ROLES = (TIME_COMPONENT_MAP.keys + ['upload_trigger']).freeze

  def perform
    eligible_version_ids = RegisterTemplate.where(group_name: 'set_system_clock', group_role: REQUIRED_ROLES, active: true)
      .group(:plc_version_id)
      .having('COUNT(DISTINCT group_role) = ?', REQUIRED_ROLES.size)
      .pluck(:plc_version_id)
    if eligible_version_ids.empty?
      return
    end

    plcs = Plc.joins(:gateway, site: :company)
      .where(active: true)
      .where(sites: { companies: { active: true } })
      .where(gateways: { active: true })
      .distinct

    plcs.find_each do |plc|
      PlcClockWriteJob.perform_async(plc.id)
    end
  end
end
