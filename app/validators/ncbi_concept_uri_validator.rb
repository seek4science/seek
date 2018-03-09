class NcbiConceptUriValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # already checked it is a valid url

    unless validate_against_purl(value) || validate_against_indentifiers(value)
      record.errors[attribute] << (options[:message] || "isn't a valid NCBI Taxonomy identifier")
    end
  end

  private

  def validate_against_purl(value)
    !(%r{\Ahttps?:\/\/purl.obolibrary.org\/obo\/NCBITaxon_\d+\Z}.match(value) ||
        %r{\Ahttps?:\/\/purl.bioontology.org\/ontology\/NCBITAXON\/\d+\Z}.match(value)).nil?
  end

  def validate_against_indentifiers(value)
    !%r{\Ahttps?:\/\/identifiers.org\/taxonomy\/\d+\Z}.match(value).nil?
  end
end
