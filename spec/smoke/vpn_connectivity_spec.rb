require 'rails_helper'

# VPN connectivity smoke tests.
#
# These specs hit the REAL VPN manager and a REAL test PLC. They're
# tagged :smoke so they're excluded from the default RSpec run.
#
# How to run
# ----------
#   VPN_MANAGER_BASE_URL=...        # already in your .env (same as app)
#   VPN_MANAGER_API_TOKEN=...       # already in your .env (same as app)
#   SMOKE_GATEWAY_LABEL=Gateway.1 \
#   SMOKE_PLC_PRIVATE_IP=10.0.0.100 \
#   SMOKE_PLC_SLAVE_ID=1 \
#   SMOKE_FIRMWARE_ID=1 \
#   SMOKE_REGISTER_LABEL=clock_seconds \
#   bundle exec rspec spec/smoke --tag smoke
#
# Set those once via a .envrc.smoke (gitignored) or a shell alias.

RSpec.describe 'VPN connectivity smoke', :smoke do
  REQUIRED_VARS = %w[
    VPN_MANAGER_BASE_URL
    VPN_MANAGER_API_TOKEN
    SMOKE_GATEWAY_LABEL
    SMOKE_PLC_PRIVATE_IP
    SMOKE_PLC_SLAVE_ID
    SMOKE_FIRMWARE_ID
    SMOKE_REGISTER_LABEL
  ].freeze

  before do
    missing = REQUIRED_VARS.select { |v| ENV[v].blank? }
    if missing.any?
      skip "Smoke env vars missing: #{missing.join(', ')}. See spec header for setup."
    end
  end

  let(:firmware) do
    fw = ModbusFirmwareVersion.find_by(id: ENV['SMOKE_FIRMWARE_ID'])
    if !fw
      skip "Firmware with ID '#{ENV['SMOKE_FIRMWARE_ID']}' not found. Did you `bin/rails db:seed RAILS_ENV=test`?"
    end
    fw
  end

  let(:gateway) do
    create(:gateway, label: ENV['SMOKE_GATEWAY_LABEL'])
  end

  let(:plc) do
    create(
      :plc,
      gateway: gateway,
      modbus_firmware_version: firmware,
      private_ip: ENV['SMOKE_PLC_PRIVATE_IP'],
      slave_id: ENV['SMOKE_PLC_SLAVE_ID'].to_i
    )
  end

  let(:measurement_point) do
    template = firmware.register_templates.find_by(label: ENV['SMOKE_REGISTER_LABEL'])
    if !template
      skip "Register label '#{ENV['SMOKE_REGISTER_LABEL']}' not on firmware " \
           "#{firmware.full_name}. Pick a label that exists."
    end

    # The PLC's after_create callback auto-builds an MP for every
    # register on the firmware, so we just look ours up.
    mp = plc.measurement_points.find_by(register_template: template)
    if !mp
      raise "MP for #{ENV['SMOKE_REGISTER_LABEL']} not auto-created on PLC. " \
            'Did the PLC factory disable the auto-create callback?'
    end
    mp
  end

  it 'reads the configured smoke register through the tunnel' do
    result = measurement_point.sync_read!

    expect(result).to eq(true),
      'sync_read! returned false. Likely causes: VPN tunnel down, ' \
      'wrong VPN_MANAGER_API_TOKEN, gateway label not registered with ' \
      'the VPN manager, or PLC unreachable on the bus.'

    measurement_point.reload
    expect(measurement_point.last_decoded_value).to be_present,
      'sync_read! succeeded but no value was stored. Persistence bug?'
    expect(measurement_point.last_decoded_value_at).to be > 30.seconds.ago,
      "last_decoded_value_at is stale (#{measurement_point.last_decoded_value_at}); " \
      'should have been touched seconds ago'
  end
end
