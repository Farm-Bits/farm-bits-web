# Value object that carries context through PlcWriteService for logging.
# Ensures every write is traceable: who initiated it, why, and which batch
# it belongs to.
#
# Usage:
#   # From a controller (user action)
#   context = PlcWriteContext.user_action(current_user)
#   service.write!(value, context: context)
#
#   # From a background job (system action)
#   context = PlcWriteContext.system_action('sun_data_sync')
#   service.write!(value, context: context)
#
#   # Multiple writes in the same batch share the same context
#   context = PlcWriteContext.user_action(current_user)
#   service.bulk_write!(entries, context: context)
#
class PlcWriteContext
  attr_reader :user, :source, :batch_id

  def initialize(user: nil, source: 'user', batch_id: nil)
    @user = user
    @source = source
    @batch_id = batch_id || SecureRandom.uuid
  end

  def self.user_action(user, batch_id: nil)
    new(user: user, source: 'user', batch_id: batch_id)
  end

  def self.system_action(source, batch_id: nil)
    new(user: nil, source: source, batch_id: batch_id)
  end

  def to_h
    {
      user: @user,
      source: @source,
      batch_id: @batch_id
    }
  end
end
