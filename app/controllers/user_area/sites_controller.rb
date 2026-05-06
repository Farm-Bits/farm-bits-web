class UserArea::SitesController < UserArea::ApplicationController
  before_action :set_site, only: [:show, :update, :destroy]

  def index
    authorize Site, :index?

    sites = policy_scope(Site).includes(:segments)
    render json: SiteSerializer.render_as_json(sites, view: :with_segments)
  end

  def show
    authorize @site

    render json: SiteSerializer.render_as_json(@site, view: :with_segments)
  end

  def create
    authorize Site, :create?

    site = current_company.sites.build(site_params)

    if site.save
      render json: SiteSerializer.render_as_json(site, view: :with_segments), status: :created
    else
      render json: { error: site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def update
    authorize @site, :update?

    if @site.update(site_params)
      render json: SiteSerializer.render_as_json(@site, view: :with_segments), status: :ok
    else
      render json: { error: @site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @site, :destroy?

    begin
      @site.destroy!
      head :no_content
    rescue => e
      render json: { error: @site.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :country, :city, :latitude, :longitude, :time_zone,
        segments_attributes: [:id, :name, :position, :_destroy]
      )
    end

    def set_site
      @site = policy_scope(Site).find(params[:id])
    end
end
