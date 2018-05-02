# Controller that handles OpenBIS Objects(Samples), currently they can only be mapped as Assays
# TODO map Samples also as SOP, maybe Studies
class OpenbisZamplesController < ApplicationController
  include Seek::Openbis::EntityControllerBase

  before_filter :seek_type

  def seek_entity
    @assay = @asset.seek_entity || Assay.new
    @seek_entity = @assay
  end

  def seek_params
    params.require(:assay).permit(:study_id, :assay_class_id, :title)
  end

  def seek_params_for_batch
    { study_id: @seek_parent_id }
  end

  def create_seek_object_for_obis(seek_params, creator, asset)
    seek_util.createObisAssay(seek_params, creator, asset)
  end

  def entity(id = nil)
    @entity = Seek::Openbis::Zample.new(@openbis_endpoint, id ? id : params[:id])
  end

  def entities
    if Seek::Openbis::ALL_TYPES == @entity_type
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).all
    else
      codes = @entity_type == Seek::Openbis::ALL_ASSAYS ? @entity_types_codes : [@entity_type]
      @entities = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    end
  end

  def entity_type
    @entity_type = params[:entity_type] || Seek::Openbis::ALL_ASSAYS
  end

  def entity_types
    case @seek_type
    when :assay then
      assay_types
    else
      raise "Don't recognized obis types for seek: #{@seek_type}"
    end
  end

  def assay_types
    @entity_types = seek_util.assay_types(@openbis_endpoint)
    @entity_types_codes = @entity_types.map(&:code)
    @entity_type_options = @entity_types_codes + [Seek::Openbis::ALL_ASSAYS, Seek::Openbis::ALL_TYPES]
  end

  def seek_type
    type = params[:seek] || :assay
    @seek_type = type.to_sym
  end
end
