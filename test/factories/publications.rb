FactoryBot.define do
  # PublicationType
  # :journal rely on the existence of the PublicationTypes
  factory(:journal, class: PublicationType) do
    title { 'Journal' }
    key { 'article' }
  end
  
  
  factory(:phdthesis, class: PublicationType) do
    title { 'Phd Thesis' }
    key { 'phdthesis' }
  end
  
  
  factory(:inproceedings, class: PublicationType) do
    title { 'InProceedings' }
    key { 'inproceedings' }
  end
  
  # Publication
  factory(:publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    sequence(:pubmed_id) { |n| n }
    projects { [FactoryBot.create(:project)] }
    association :contributor, factory: :person, strategy: :create
    association :publication_type, factory: :journal
  end
  
  factory(:min_publication, class: Publication) do
    with_project_contributor
    title { 'A Minimal Publication' }
    doi { 'https://doi.org/10.5075/abcd' }
    projects { [FactoryBot.create(:min_project)] }
    association :publication_type, factory: :journal
  end
  
  factory(:max_publication, class: Publication) do
    with_project_contributor
    title { 'A Maximal Publication' }
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    misc_links { [FactoryBot.build(:misc_link, label:'A link')] }
    journal { 'Journal of Molecular Biology' }
    published_date { '2017-10-10' }
    doi { 'https://doi.org/10.5072/abcd' }
    pubmed_id { '873864488' }
    citation { 'JMB Oct 2017, 12:234-245' }
    # Max publication is compared to a fixture (JSON) so we cannot use the sequence in case this factory is used twice
    publication_authors { [FactoryBot.create(:one_publication_author), FactoryBot.create(:one_registered_publication_author)] }
    abstract { 'Amazing insights into the mechanism of TF2' }
    editor { 'Richling, S. and Baumann, M. and Heuveline, V.' }
    booktitle { 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016' }
    publisher { 'Heidelberg University Library, heiBOOKS' }
    publication_type_id { FactoryBot.create(:journal).id }
    events {[FactoryBot.build(:event, policy: FactoryBot.create(:public_policy))]}
    workflows {[FactoryBot.build(:workflow, policy: FactoryBot.create(:public_policy))]}
    investigations {[FactoryBot.build(:public_investigation)]}
    studies {[FactoryBot.build(:public_study)]}
    assays {[FactoryBot.build(:public_assay)]}
    data_files {[FactoryBot.build(:public_data_file)]}
    models {[FactoryBot.build(:public_model)]}
    presentations {[FactoryBot.build(:public_presentation)]}
    association :publication_type, factory: :journal
    after(:create) do |publication|
      publication.content_blob = FactoryBot.create(:min_content_blob, content_type: 'application/pdf', asset: publication, asset_version: 1)
    end
  end
  
  factory(:publication_with_author, class: Publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    journal { 'Journal of Molecular Biology' }
    sequence( :published_date) { |n| "2017-10-#{n}" }
    citation { 'JMB Oct 2017, 12:234-245' }
    # Max publication is compared to a fixture (JSON) so we cannot use the sequence in case this factory is used twice
    publication_authors { [FactoryBot.create(:publication_author)] }
    abstract { 'Amazing insights into the mechanism of TF2' }
    editor { 'Richling, S. and Baumann, M. and Heuveline, V.' }
    booktitle { 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016' }
    publisher { 'Heidelberg University Library, heiBOOKS' }
    publication_type_id { FactoryBot.create(:journal).id }
    projects { [FactoryBot.create(:project)] } # max_project does not use sequence in the title so cannot be reused.
  end
  
  factory(:publication_with_model_and_data_file, class: Publication) do
    title { 'A Publication with Model and Data File' }
    doi { 'https://doi.org/10.5072/abcd' }
    projects { [FactoryBot.create(:min_project)] }
    models {[FactoryBot.build(:teusink_jws_model, policy: FactoryBot.create(:public_policy))]}
    data_files {[FactoryBot.build(:data_file, policy: FactoryBot.create(:public_policy))]}
    publication_type_id { FactoryBot.create(:journal).id }
    #association :models, factory: :teusink_jws_model
    #association :data_files, factory: :data_file
  end
  
  factory(:publication_with_date, class: Publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    journal { 'Journal of Molecular Biology' }
    sequence( :published_date) { |n| "2017-10-#{n}" }
    sequence(:pubmed_id) { |n| n }
    projects { [FactoryBot.create(:project)] } # max_project does not use sequence in the title so cannot be reused.
    association :contributor, factory: :person, strategy: :create
    association :publication_type, factory: :journal
  end
  
  # PublicationAuthor
  factory :publication_author do
    sequence(:first_name) { |n| "Author#{n}" }
    last_name { 'Last' }
  end
  
  factory :registered_publication_author, parent: :publication_author do
    association :person, factory: :person
  end
  
  # PublicationAuthor
  factory :one_publication_author, parent: :publication_author do
    first_name { 'Author_non_registered' }
    last_name { 'LastNonReg' }
  end
  
  factory :one_registered_publication_author, parent: :publication_author do
    association :person,  factory: :person
    first_name { 'Author_registered' }
    last_name { 'LastReg' }
  end
end
