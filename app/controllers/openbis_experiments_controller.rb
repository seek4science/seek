# Controller that registers OpenBIS Experiments as Study
class OpenbisExperimentsController < ApplicationController
  include Seek::Openbis::EntityControllerBase

  def seek_entity
    @study = @asset.seek_entity || Study.new
    @seek_entity = @study
  end

  def seek_params
    params.require(:study).permit(:investigation_id)
  end

  def seek_params_for_batch
    { investigation_id: @seek_parent_id }
  end

  def create_seek_object_for_obis(seek_params, creator, asset)
    seek_util.createObisStudy(seek_params, creator, asset)
  end

  def entity(id = nil)
    @entity = Seek::Openbis::Experiment.new(@openbis_endpoint, id ? id : params[:id])
  end

  def entities
    if Seek::Openbis::ALL_TYPES == @entity_type
      @entities = Seek::Openbis::Experiment.new(@openbis_endpoint).all
    else
      codes = @entity_type == Seek::Openbis::ALL_STUDIES ? @entity_types_codes : [@entity_type]
      @entities = Seek::Openbis::Experiment.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def entity_type
    @entity_type = params[:entity_type] || Seek::Openbis::ALL_STUDIES
  end

  def entity_types
    study_types
  end

  def study_types
    @entity_types = seek_util.study_types(@openbis_endpoint)
    @entity_types_codes = @entity_types.map(&:code)
    @entity_type_options = @entity_types_codes + [Seek::Openbis::ALL_STUDIES, Seek::Openbis::ALL_TYPES]
  end
end
