class UserArea::SitesController < UserArea::ApplicationController
  before_action :set_site, only: [:update, :destroy]

  def create
    authorize Site, :create?

    site = Site.new(site_params)
    site.client = current_client

    if site.save
      render json: SiteSerializer.render(site), status: :created
    else
      render json: { error: site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def update
    authorize @site, :update?

    if @site.update(site_params)
      render json: SiteSerializer.render(@site), status: :ok
    else
      render json: { error: @site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @site, :destroy?

    if @site.update(active: false)
      head :no_content
    else
      render json: { error: @site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :country, :city, :latitude, :longitude, :altitude)
    end

    def set_site
      @site = current_client.sites.find_by(id: params[:id])
    end
end
