class PlcManufacturersController < ApplicationController
  before_action :set_plc_manufacturer, only: %i[ show edit update destroy ]

  # GET /plc_manufacturers
  def index
    @plc_manufacturers = PlcManufacturer.all
    render inertia: 'plc_manufacturers/index', props: {
      plc_manufacturers: @plc_manufacturers
    }
  end

  # GET /plc_manufacturers/1
  def show
  end

  # GET /plc_manufacturers/new
  def new
    @plc_manufacturer = PlcManufacturer.new
  end

  # GET /plc_manufacturers/1/edit
  def edit
  end

  # POST /plc_manufacturers
  def create
    @plc_manufacturer = PlcManufacturer.new(plc_manufacturer_params)

    if @plc_manufacturer.save
      redirect_to @plc_manufacturer, notice: 'Plc manufacturer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /plc_manufacturers/1
  def update
    if @plc_manufacturer.update(plc_manufacturer_params)
      redirect_to @plc_manufacturer, notice: 'Plc manufacturer was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /plc_manufacturers/1
  def destroy
    @plc_manufacturer.destroy
    redirect_to plc_manufacturers_url, notice: 'Plc manufacturer was successfully destroyed.', status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plc_manufacturer
      @plc_manufacturer = PlcManufacturer.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def plc_manufacturer_params
      params.require(:plc_manufacturer).permit(:name)
    end
end
