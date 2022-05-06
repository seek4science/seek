# Sop
Factory.define(:sop) do |f|
  f.title 'This Sop'
  f.with_project_contributor

  f.after_create do |sop|
    if sop.content_blob.blank?
      sop.content_blob = Factory.create(:content_blob, original_filename: 'sop.pdf',
                                        content_type: 'application/pdf', asset: sop, asset_version: sop.version)
    else
      sop.content_blob.asset = sop
      sop.content_blob.asset_version = sop.version
      sop.content_blob.save
    end
  end
end

Factory.define(:public_sop, parent: :sop) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:min_sop, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Minimal Sop'
  f.projects { [Factory(:min_project)] }
  f.after_create do |sop|
    sop.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: sop, asset_version: sop.version)
  end
end

Factory.define(:max_sop, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Maximal Sop'
  f.description 'How to run a simulation in GROMACS'
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.assays { [Factory(:public_assay)] }
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |sop|
    sop.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: sop, asset_version: sop.version)
    sop.annotate_with(['Sop-tag1', 'Sop-tag2', 'Sop-tag3', 'Sop-tag4', 'Sop-tag5'], 'tag', sop.contributor)
    sop.save!
  end
  f.other_creators 'Blogs, Joe'
  f.assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
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

Factory.define(:api_pdf_sop, parent: :sop) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end
