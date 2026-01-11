class UserArea::PlcsController < UserArea::ApplicationController
  before_action :set_plc, only: [:show, :update]

  def show
    authorize @plc, :show?

    segments_for_site = []
    if @plc.site_id
      segments_for_site = policy_scope(Segment)
        .select(:id, :name)
        .where(site_id: @plc.site_id)
        .order(:name)
        .map { |s| { id: s.id, name: s.name } }
    end
    data = {
      plc: PlcSerializer.render_as_hash(@plc, view: :with_interfaces),
      segments: segments_for_site,
      measurementSubtypes: MeasurementSubtypeSerializer.render_as_hash(measurement_subtypes)
    }

    respond_to do |format|
      format.html { render inertia: 'UserArea/Plcs/show', props: data }
      format.json { render json: data, status: :ok }
    end
  end

  def update
    authorize @plc, :update?

    if @plc.update(plc_params)
      @plc = policy_scope(Plc)
        .includes(plc_includes_for_serializer)
        .find(@plc.id)
      render json: PlcSerializer.render(@plc, view: :with_interfaces), status: :ok
    else
      render json: { error: @plc.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private
    def plc_params
      params.require(:plc).permit(:name)
    end

    def plc_includes_for_serializer
      [
        :model,
        :measurement_points,
        {
          measurement_points: [
            :measurement_subtype,
            { register_template: :interface_register_mappings }
          ]
        },
        {
          plc_version: {
            interfaces: {
              interface_register_mappings: :register_template
            }
          }
        }
      ]
    end

    def set_plc
      @plc = policy_scope(Plc)
        .includes(plc_includes_for_serializer)
        .find(params[:id])
    end

    def measurement_subtypes
      MeasurementSubtype
        .includes(:measurement_type)
        .joins(:measurement_type)
        .order('measurement_types.position, measurement_subtypes.position')
    end
end
