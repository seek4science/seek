# Sop
Factory.define(:sop) do |f|
  f.title 'This Sop'
  f.with_project_contributor

  f.after_create do |sop|
    if sop.content_blob.blank?
      sop.content_blob = Factory.create(:content_blob, content_type: 'application/pdf', asset: sop, asset_version: sop.version)
    else
      sop.content_blob.asset = sop
      sop.content_blob.asset_version = sop.version
      sop.content_blob.save
    end
  end
end

Factory.define(:min_sop, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Minimal Sop'
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |sop|
    sop.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: sop, asset_version: sop.version)
  end
end

Factory.define(:max_sop, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Maximal Sop'
  f.description 'How to run a simulation in GROMACS'
  f.projects { [Factory.build(:max_project)] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |sop|
    sop.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: sop, asset_version: sop.version)
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:doc_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :doc_content_blob
end

Factory.define(:odt_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :odt_content_blob
end

Factory.define(:pdf_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :pdf_content_blob
end

# A SOP that has been registered as a URI
Factory.define(:url_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :url_content_blob
end

# Sop::Version
Factory.define(:sop_version, class: Sop::Version) do |f|
  f.association :sop
  f.projects { sop.projects }
  f.after_create do |sop_version|
    sop_version.sop.version += 1
    sop_version.sop.save
    sop_version.version = sop_version.sop.version
    sop_version.title = sop_version.sop.title
    sop_version.save
  end
end

Factory.define(:sop_version_with_blob, parent: :sop_version) do |f|
  f.after_create do |sop_version|
    if sop_version.content_blob.blank?
      sop_version.content_blob = Factory.create(:pdf_content_blob,
                                                asset: sop_version.sop,
                                                asset_version: sop_version.version)
    else
      sop_version.content_blob.asset = sop_version.sop
      sop_version.content_blob.asset_version = sop_version.version
      sop_version.content_blob.save
    end
  end
end

# ExperimentalCondition
Factory.define(:experimental_condition) do |f|
  f.start_value 1
  f.sop_version 1
  f.association :measured_item, factory: :measured_item
  f.association :unit, factory: :unit
  f.association :sop, factory: :sop
  f.experimental_condition_links { [ExperimentalConditionLink.new(substance: Factory(:compound))] }
end

# ExperimentalConditionLink
Factory.define(:experimental_condition_link) do |f|
  f.association :substance, factory: :compound
  f.association :experimental_condition
end

# StudiedFactor
Factory.define(:studied_factor) do |f|
  f.start_value 1
  f.end_value 10
  f.standard_deviation 2
  f.data_file_version 1
  f.association :measured_item, factory: :measured_item
  f.association :unit, factory: :unit
  f.studied_factor_links { [StudiedFactorLink.new(substance: Factory(:compound))] }
  f.association :data_file, factory: :data_file
end

# StudiedFactorLink
Factory.define(:studied_factor_link) do |f|
  f.association :substance, factory: :compound
  f.association :studied_factor
end

# MeasuredItem
Factory.define(:measured_item) do |f|
  f.title 'concentration'
end

# Compound
Factory.define(:compound) do |f|
  f.sequence(:name) { |n| "glucose #{n}" }
end

# Synonym
Factory.define :synonym do |f|
  f.name 'coffee'
  f.association :substance, factory: :compound
end

# MappingLink
Factory.define :mapping_link do |f|
  f.association :substance, factory: :compound
  f.association :mapping, factory: :mapping
end

# Mapping
Factory.define :mapping do |f|
  f.chebi_id '12345'
  f.kegg_id '6789'
  f.sabiork_id '4'
end

Factory.define(:api_pdf_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end
