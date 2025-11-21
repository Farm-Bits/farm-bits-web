class UserArea::ProtocolsController < UserArea::ApplicationController
  before_action :set_protocol, only: %i[ show edit update destroy ]

  def index
    render inertia: 'UserArea/Protocols/Index'
  end

  def show
  end

  def new
    render inertia: 'UserArea/Protocols/ProtocolList'
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end

  private
    def set_protocol
    end

    def protocol_params
      params.require(:protocol).permit()
    end
end
