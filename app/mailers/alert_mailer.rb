class AlertMailer < ApplicationMailer
  self.delivery_method = :onesignal

  def alert_opened(alert_id, user_id)
    @alert = Alert.find_by(id: alert_id)
    @user  = User.find_by(id: user_id)
    if @alert.nil? || @user.nil?
      return
    end

    mail(
      to:      @user.email,
      subject: subject_for(@alert, lifecycle: :opened)
    )
  end

  def alert_closed(alert_id, user_id)
    @alert = Alert.find_by(id: alert_id)
    @user  = User.find_by(id: user_id)
    if @alert.nil? || @user.nil?
      return
    end

    mail(
      to:      @user.email,
      subject: subject_for(@alert, lifecycle: :closed)
    )
  end

  private
    def subject_for(alert, lifecycle:)
      severity_label = alert.severity.upcase
      verb           = lifecycle == :opened ? 'fired' : 'cleared'
      "[#{severity_label}] Alert #{verb}: #{alert.measurement_point_name} (#{alert.segment_name})"
    end
end
