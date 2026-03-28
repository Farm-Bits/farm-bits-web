class DeviseOnesignalMailer < Devise::Mailer
  self.delivery_method = :onesignal

  helper :application
  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
end
