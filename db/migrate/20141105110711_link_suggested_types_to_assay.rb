class LinkSuggestedTypesToAssay < ActiveRecord::Migration

  def up
    update_for "assay_type"
    update_for "technology_type"
  end

  def down
  end

  private

  def update_for type_prefix
    sql = "SELECT id,#{type_prefix}_uri FROM assays"
    records = ActiveRecord::Base.connection.select_rows(sql)
    assays_with_uuid = records.select { |rec| !valid_uri?(rec[1]) && !rec[1].blank? }
    puts "#{assays_with_uuid.size} assays found that need updating for #{type_prefix}"
    assays_with_uuid.each do |assay|
      uri = assay[1]
      if record=find_suggested_type_record(uri,type_prefix)
        ontology_uri = find_ontology_parent_uri(uri,type_prefix)
        update_assay(assay[0],record["id"],ontology_uri,type_prefix)
      end
    end
  end

  def update_assay assay_id,suggested_type_id,uri,prefix
    sql = "UPDATE assays SET #{prefix}_uri='#{uri}',suggested_#{prefix}_id=#{suggested_type_id} WHERE id=#{assay_id}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def valid_uri? uri
    RDF::URI.new(uri).valid?
  end

  def find_ontology_parent_uri uri,prefix
    return uri if valid_uri?(uri)
    find_ontology_parent_uri(find_suggested_type_record(uri,prefix)["parent_uri"],prefix)
  end

  def find_suggested_type_record(uri,prefix)
    sql = "SELECT id,parent_uri FROM suggested_#{prefix.pluralize} WHERE uri='#{uri}'"
    ActiveRecord::Base.connection.select_one(sql)
  end
end
