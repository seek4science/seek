FactoryBot.define do
  # Presentation
  factory(:presentation) do
    sequence(:title) { |n| "A Presentation #{n}" }
    with_project_contributor
  
    after(:create) do |presentation|
      if presentation.content_blob.blank?
        presentation.content_blob = FactoryBot.create(:content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
      else
        presentation.content_blob.asset = presentation
        presentation.content_blob.asset_version = presentation.version
        presentation.content_blob.save
      end
    end
  end
  
  factory(:min_presentation, class: Presentation) do
    with_project_contributor
    title { 'A Minimal Presentation' }
    after(:create) do |presentation|
      presentation.content_blob = FactoryBot.create(:min_content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
    end
  end
  
  factory(:max_presentation, class: Presentation) do
    with_project_contributor
    title { 'A Maximal Presentation' }
    description { 'Non-equilibrium Free Energy Calculations and their caveats' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    assays { [FactoryBot.create(:public_assay)] }
    events {[FactoryBot.build(:event, policy: FactoryBot.create(:public_policy))]}
    workflows {[FactoryBot.build(:workflow, policy: FactoryBot.create(:public_policy))]}
    relationships {[FactoryBot.create(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication))]}
    after(:create) do |presentation|
      presentation.content_blob = FactoryBot.create(:min_content_blob, original_filename: 'test.pdf', content_type: 'application/pdf', asset: presentation, asset_version: presentation.version)
      presentation.annotate_with(['Presentation-tag1', 'Presentation-tag2', 'Presentation-tag3', 'Presentation-tag4', 'Presentation-tag5'], 'tag', presentation.contributor)
      presentation.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:ppt_presentation, parent: :presentation) do
    association :content_blob, factory: :ppt_content_blob
  end
  
  factory(:odp_presentation, parent: :presentation) do
    association :content_blob, factory: :odp_content_blob
  end
  
  factory(:api_pdf_presentation, parent: :presentation) do
    association :content_blob, factory: :blank_pdf_content_blob
  end
  
  # Presentation::Version
  factory(:presentation_version, class: Presentation::Version) do
    association :presentation
    projects { presentation.projects }
    after(:create) do |presentation_version|
      presentation_version.presentation.version += 1
      presentation_version.presentation.save
      presentation_version.version = presentation_version.presentation.version
      presentation_version.title = presentation_version.presentation.title
      presentation_version.save
    end
  end
  
  factory(:presentation_version_with_blob, parent: :presentation_version) do
    after(:create) do |presentation_version|
      if presentation_version.content_blob.blank?
        presentation_version.content_blob = FactoryBot.create(:content_blob, original_filename: 'test.pdf',
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
  
  factory(:presentation_with_specified_project, class: Presentation) do
    projects { [FactoryBot.create(:project, title: 'Specified Project')] }
    with_project_contributor
    title { 'Pres With Specified Project' }
  end
  
  factory(:public_presentation, parent: :presentation) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:presentation_version_with_remote_content, parent: :presentation_version) do
    after(:create) do |presentation_version|
      if presentation_version.content_blob.blank?
        presentation_version.content_blob = FactoryBot.create(:content_blob, url: "https://www.youtube.com/watch?v=Ffbl_6p_MRQ",
                                                           asset: presentation_version.presentation,
                                                           asset_version: presentation_version)
      else
        presentation_version.content_blob.asset = presentation_version.presentation
        presentation_version.content_blob.asset_version = presentation_version.version
        presentation_version.content_blob.save
      end
    end
  end
end
