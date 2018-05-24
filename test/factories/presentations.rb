# Presentation
Factory.define(:presentation) do |f|
  f.sequence(:title) { |n| "A Presentation #{n}" }
  f.association :contributor, factory: :person

  f.after_build do |presentation|
    presentation.projects = [presentation.contributor.person.projects.first] if presentation.projects.empty?
  end

  f.after_create do |presentation|
    if presentation.content_blob.blank?
      presentation.content_blob = Factory.create(:content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
    else
      presentation.content_blob.asset = presentation
      presentation.content_blob.asset_version = presentation.version
      presentation.content_blob.save
    end
  end
end

Factory.define(:min_presentation, class: Presentation) do |f|
  f.with_project_contributor
  f.title 'A Minimal Presentation'
  f.after_create do |presentation|
    presentation.content_blob = Factory.create(:min_content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
  end
end

Factory.define(:max_presentation, class: Presentation) do |f|
  f.with_project_contributor
  f.title 'A Maximal Presentation'
  f.description 'Non-equilibrium Free Energy Calculations and their caveats'
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.events {[Factory.build(:event, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |presentation|
    presentation.content_blob = Factory.create(:min_content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:ppt_presentation, parent: :presentation) do |f|
  f.association :content_blob, factory: :ppt_content_blob
end

Factory.define(:odp_presentation, parent: :presentation) do |f|
  f.association :content_blob, factory: :odp_content_blob
end

Factory.define(:api_pdf_presentation, parent: :presentation) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end

# Presentation::Version
Factory.define(:presentation_version, class: Presentation::Version) do |f|
  f.association :presentation
  f.projects { presentation.projects }
  f.after_create do |presentation_version|
    presentation_version.presentation.version += 1
    presentation_version.presentation.save
    presentation_version.version = presentation_version.presentation.version
    presentation_version.title = presentation_version.presentation.title
    presentation_version.save
  end
end

Factory.define(:presentation_version_with_blob, parent: :presentation_version) do |f|
  f.after_create do |presentation_version|
    if presentation_version.content_blob.blank?
      presentation_version.content_blob = Factory.create(:content_blob, original_filename: 'test.pdf',
                                                         content_type: 'application/pdf',
                                                         asset: presentation_version.presentation,
                                                         asset_version: presentation_version)
    else
      presentation_version.content_blob.asset = presentation_version.presentation
      presentation_version.content_blob.asset_version = presentation_version.version
      presentation_version.content_blob.save
    end
  end
end

Factory.define(:presentation_with_specified_project, class: Presentation) do |f|
  f.projects { [Factory(:project, title: 'Specified Project')] }
  f.with_project_contributor
  f.title 'Pres With Specified Project'
end
