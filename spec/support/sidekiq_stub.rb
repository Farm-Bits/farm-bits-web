require 'sidekiq/testing'

# Don't actually enqueue or run background jobs during tests.
# Jobs that get triggered by model callbacks (PlcIngestionCreateJob,
# ModbusRefreshJob, etc.) will be recorded but not executed.
Sidekiq::Testing.fake!

RSpec.configure do |config|
  # Reset the in-memory job list between tests so jobs from one test
  # don't bleed into another.
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
