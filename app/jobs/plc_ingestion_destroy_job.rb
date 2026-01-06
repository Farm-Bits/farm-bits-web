class PlcIngestionDestroyJob < ApplicationJob
  queue_as :default

  def perform(email)
    PlcIngestionClient.delete_authorized_email(email)
  end
end
