class TechnologyTypeUriValidator < ActiveModel::Validator
  def validate(assay)
    return if assay.technology_type_uri.blank?
    unless assay.valid_technology_type_uri?
      assay.errors[:technology_type_uri] << 'needs to be a valid term from the ontology'
    end
  end
end
