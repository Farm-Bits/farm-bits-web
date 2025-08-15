class PlcModelsController < ApplicationController
  before_action :set_plc_model, only: %i[ show edit update destroy ]

  # GET /plc_models
  def index
    @plc_models = PlcModel.all
    render inertia: 'plc_models/index', props: {
      plc_models: @plc_models
    }
  end

  # GET /plc_models/1
  def show
  end

  # GET /plc_models/new
  def new
    @plc_model = PlcModel.new
  end

  # GET /plc_models/1/edit
  def edit
  end

  # POST /plc_models
  def create
    @plc_model = PlcModel.new(plc_model_params)

    if @plc_model.save
      redirect_to @plc_model, notice: 'Plc model was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /plc_models/1
  def update
    if @plc_model.update(plc_model_params)
      redirect_to @plc_model, notice: 'Plc model was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /plc_models/1
  def destroy
    @plc_model.destroy
    redirect_to plc_models_url, notice: 'Plc model was successfully destroyed.', status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plc_model
      @plc_model = PlcModel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def plc_model_params
      params.require(:plc_model).permit(:name, :plc_manufacturer_id)
    end
end
