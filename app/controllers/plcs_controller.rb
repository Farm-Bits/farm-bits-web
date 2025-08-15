class PlcsController < ApplicationController
  before_action :set_plc, only: %i[ show edit update destroy ]

  # GET /plcs
  def index
    @plcs = Plc.all
    render inertia: 'plcs/index', props: {
      plcs: @plcs
    }
  end

  # GET /plcs/1
  def show
  end

  # GET /plcs/new
  def new
    @plc = Plc.new
  end

  # GET /plcs/1/edit
  def edit
  end

  # POST /plcs
  def create
    @plc = Plc.new(plc_params)

    if @plc.save
      redirect_to @plc, notice: 'Plc was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /plcs/1
  def update
    if @plc.update(plc_params)
      redirect_to @plc, notice: 'Plc was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /plcs/1
  def destroy
    @plc.destroy
    redirect_to plcs_url, notice: 'Plc was successfully destroyed.', status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plc
      @plc = Plc.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def plc_params
      params.require(:plc).permit(:name)
    end
end
