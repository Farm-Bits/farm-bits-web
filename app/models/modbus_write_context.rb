class ModbusWriteContext
  attr_reader :user, :source, :batch_id

  def self.user_action(user, batch_id: SecureRandom.uuid)
    new(user: user, source: 'user', batch_id: batch_id)
  end

  def self.system_action(source, batch_id: SecureRandom.uuid)
    new(user: nil, source: source, batch_id: batch_id)
  end

  def initialize(user:, source:, batch_id:)
    @user     = user
    @source   = source
    @batch_id = batch_id
  end

  def user_action?
    user.present?
  end

  def system_action?
    user.nil?
  end
end
