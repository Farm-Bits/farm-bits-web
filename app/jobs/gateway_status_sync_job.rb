# Periodic reconciliation of gateway VPN connection status.
#
# Pulls authoritative status from the VPN manager and mirrors it onto local
# Gateway records via Gateway#apply_status!. This is the backstop that corrects
# any status push (Slice D) that was missed — VPN manager restart, main-app
# downtime, or a dropped HTTP call. Matching is by label.
#
# Idempotent: writes only when the local mirror diverges from the remote truth,
# so a steady state produces no DB writes and matching values never clobber a
# fresher push.
class GatewayStatusSyncJob
  include Sidekiq::Job
  sidekiq_options queue: 'default', retry: false

  def perform
    remote_rows = VpnManagerClient.new.gateway_statuses

    local_by_label = Gateway
      .where(label: remote_rows.map { |r| r[:label] })
      .index_by(&:label)

    remote_rows.each do |row|
      reconcile(local_by_label[row[:label]], row)
    end
  rescue StandardError => e
    # A cron job's retry is the next scheduled run; don't crash-loop.
    Rails.logger.error("[GatewayStatusSyncJob] sync aborted: #{e.class} - #{e.message}")
  end

  private
    def reconcile(gateway, row)
      if gateway.nil?
        return
      end

      remote_status = row[:connection_status].to_s

      if !Gateway::CONNECTION_STATUSES.include?(remote_status)
        Rails.logger.warn(
          "[GatewayStatusSyncJob] unrecognized status '#{remote_status}' " \
          "for label #{row[:label]}; skipping"
        )
        return
      end

      if gateway.connection_status == remote_status
        return
      end

      gateway.apply_status!(remote_status, status_updated_at: status_timestamp(row))
    rescue StandardError => e
      Rails.logger.error(
        "[GatewayStatusSyncJob] failed to apply status for gateway " \
        "#{gateway.id} (label #{row[:label]}): #{e.class} - #{e.message}"
      )
    end

    # Source-side timestamp for the stale guard. Prefer the VPN manager's row
    # write-time (monotonic per record); fall back to last_connected_at, then
    # to fetch time.
    def status_timestamp(row)
      raw = row[:remote_updated_at] || row[:last_connected_at]

      if raw.present?
        return Time.zone.parse(raw.to_s)
      end

      Time.current
    end
end
