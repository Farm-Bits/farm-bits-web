class PlcIngestionCreateJob < ApplicationJob
  queue_as :default

  def perform(plc_id)
    plc = Plc.find_by_id(plc_id)
    if !plc
      return
    end

    PlcIngestionClient.create_authorized_email(plc)
  end
end
