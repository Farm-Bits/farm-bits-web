class UserSessionMailer < ApplicationMailer
  def otp_code(user_session, code)
    @code         = code
    @client_name  = user_session.client_name
    @ip_address   = user_session.ip_address
    @expires_in   = UserSession::OTP_VALIDITY

    mail(
      to:      user_session.authenticatable.email,
      subject: 'Your sign-in code'
    )
  end
end
