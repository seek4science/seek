class OpenbisExternalAsset < ExternalAsset


  def self.create(openbis_entity, sync_options)


    unless openbis_entity && openbis_entity.openbis_endpoint
      raise 'OpenbisEntity with configured endpoint is required'
    end

    asset = OpenbisExternalAsset.new
    openbis_endpoint = openbis_entity.openbis_endpoint
    sync_options = {} unless sync_options

    asset.seek_service = openbis_endpoint
    asset.external_service = openbis_endpoint.web_endpoint
    asset.external_id = openbis_entity.perm_id
    asset.external_type = "#{openbis_entity.class}"
    asset.sync_options = sync_options

    asset.content = openbis_entity
    return asset
  end

  def extract_mod_stamp(openbis_entity)
    openbis_entity.modification_date.to_s
  end

end