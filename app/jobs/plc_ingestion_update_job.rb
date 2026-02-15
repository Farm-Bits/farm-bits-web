class PlcIngestionUpdateJob
  include Sidekiq::Job
  queue_as :critical

  def perform(plc_id, previous_username, password_changed)
    plc = Plc.find_by_id(plc_id)
    if !plc
      return
    end

    PlcIngestionClient.update_authorized_email(
      plc,
      previous_username,
      password_changed
    )
  end
end
