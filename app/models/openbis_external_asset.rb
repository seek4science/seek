class OpenbisExternalAsset < ExternalAsset


  def self.build(openbis_entity, sync_options=nil)
    new.populate_from_obis(openbis_entity, sync_options)
  end

  def self.registered?(openbis_entity)
    exists?(external_service: extract_external_service(openbis_entity), external_id: openbis_entity.perm_id)
  end

  def self.find_by_entity(openbis_entity)
    where(external_service: extract_external_service(openbis_entity), external_id: openbis_entity.perm_id).first!
  end

  def self.find_or_create_by_entity(openbis_entity)
    asset = where(external_service: extract_external_service(openbis_entity), external_id: openbis_entity.perm_id).first
    return asset ? asset : OpenbisExternalAsset.build(openbis_entity)
  end

  def self.extract_external_service(openbis_entity)
    openbis_entity.openbis_endpoint.web_endpoint
  end

  def populate_from_obis(openbis_entity, sync_options)
    unless openbis_entity && openbis_entity.openbis_endpoint
      raise 'OpenbisEntity with configured endpoint is required'
    end

    openbis_endpoint = openbis_entity.openbis_endpoint
    sync_options = {} unless sync_options

    self.seek_service = openbis_endpoint
    self.external_service = self.class.extract_external_service(openbis_entity)
    self.external_id = openbis_entity.perm_id
    self.external_type = "#{openbis_entity.class}"
    self.sync_options = sync_options

    self.content = openbis_entity
    self

  end


  def extract_mod_stamp(openbis_entity)
    openbis_entity.modification_date.to_s
  end

  def deserialize_content(serial)
    return nil if serial.nil?

    entity = external_type.constantize.new(seek_service)
    entity.populate_from_json(JSON.parse serial)
  end

  def search_terms
    super | openbis_search_terms
  end

  def openbis_search_terms
    entity = content

    return [] unless entity

    terms = [entity.perm_id, entity.type_code, entity.type_description,
             entity.registrator, entity.modifier, entity.code]

    if entity.properties
      terms |= entity.properties.map { |key, value| [value, "#{key}:#{value}"]}.flatten
    end

    if entity.is_a? Seek::Openbis::Dataset

      terms |= entity.dataset_files_no_directories.collect do |file|
        # files dont have permid [file.perm_id, file.path, file.filename]
        [file.path, file.filename]
      end.flatten


    end

    terms.uniq
  end

end