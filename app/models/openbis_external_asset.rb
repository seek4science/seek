class OpenbisExternalAsset < ExternalAsset


  def self.build(openbis_entity, sync_options)


    OpenbisExternalAsset.new.populate_from_obis(openbis_entity, sync_options)
  end

  def populate_from_obis(openbis_entity, sync_options)
    unless openbis_entity && openbis_entity.openbis_endpoint
      raise 'OpenbisEntity with configured endpoint is required'
    end

    openbis_endpoint = openbis_entity.openbis_endpoint
    sync_options = {} unless sync_options

    self.seek_service = openbis_endpoint
    self.external_service = openbis_endpoint.web_endpoint
    self.external_id = openbis_entity.perm_id
    self.external_type = "#{openbis_entity.class}"
    self.sync_options = sync_options

    self.content = openbis_entity
    self

  end

  def extract_mod_stamp(openbis_entity)
    openbis_entity.modification_date.to_s
  end

end