class SyncPlcIngestionEmailJob < ActiveJob::Base
  queue_as :default

  def perform(plc_id, action)
    plc = Plc.find(plc_id)

    case action
    when 'create'
      PlcIngestionClient.authorize_email(plc.username, active: true)
    when 'update'
      PlcIngestionClient.update_email(plc.username, active: plc.active?)
    when 'destroy'
      PlcIngestionClient.revoke_email(plc.username)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "PLC #{plc_id} not found, skipping ingestion email sync"
  end
end
