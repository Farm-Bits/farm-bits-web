class PlcIngestionDestroyJob
  include Sidekiq::Job
  sidekiq_options queue: 'critical'

  def perform(email)
    PlcIngestionClient.delete_authorized_email(email)
  end
end
