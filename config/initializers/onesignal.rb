Rails.application.config.after_initialize do
  ActionMailer::Base.add_delivery_method(:onesignal, OnesignalDeliveryMethod)
end
