class PlcIngestionDestroyJob < ApplicationJob
  queue_as :critical

  def perform(email)
    PlcIngestionClient.delete_authorized_email(email)
  end
end
