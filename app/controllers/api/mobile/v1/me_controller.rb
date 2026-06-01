class Api::Mobile::V1::MeController < Api::Mobile::V1::BaseController
  def show
    payload = authenticated_payload(current_user_session, nil)
    payload.delete(:token)
    payload.delete(:landing)
    render json: payload
  end
end
