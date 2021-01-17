class AssayTypeUriValidator < ActiveModel::Validator
  def validate(assay)
    return if assay.assay_type_uri.blank?
    unless assay.valid_assay_type_uri?
      assay.errors[:assay_type_uri] << 'needs to be a valid term from the ontology'
    end
  end
end
