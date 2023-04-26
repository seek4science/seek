FactoryBot.define do
  # PublicationType
  # :journal rely on the existence of the PublicationTypes
  factory(:journal, class: PublicationType) do
    title 'Journal'
    key 'article'
  end
  
  
  factory(:phdthesis, class: PublicationType) do
    title 'Phd Thesis'
    key 'phdthesis'
  end
  
  
  factory(:inproceedings, class: PublicationType) do
    title 'InProceedings'
    key 'inproceedings'
  end
  
  # Publication
  factory(:publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    sequence(:pubmed_id) { |n| n }
    projects { [Factory(:project)] }
    association :contributor, factory: :person
    association :publication_type, factory: :journal
  end
  
  factory(:min_publication, class: Publication) do
    with_project_contributor
    title 'A Minimal Publication'
    doi 'https://doi.org/10.5075/abcd'
    projects { [Factory(:min_project)] }
    association :publication_type, factory: :journal
  end
  
  factory(:max_publication, class: Publication) do
    with_project_contributor
    title 'A Maximal Publication'
    discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
    misc_links { [Factory.build(:misc_link, label:'A link')] }
    journal 'Journal of Molecular Biology'
    published_date '2017-10-10'
    doi 'https://doi.org/10.5072/abcd'
    pubmed_id '873864488'
    citation 'JMB Oct 2017, 12:234-245'
    # Max publication is compared to a fixture (JSON) so we cannot use the sequence in case this factory is used twice
    publication_authors { [Factory(:one_publication_author), Factory(:one_registered_publication_author)] }
    abstract 'Amazing insights into the mechanism of TF2'
    editor 'Richling, S. and Baumann, M. and Heuveline, V.'
    booktitle 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016'
    publisher 'Heidelberg University Library, heiBOOKS'
    publication_type_id  Factory(:journal).id
    events {[Factory.build(:event, policy: Factory(:public_policy))]}
    workflows {[Factory.build(:workflow, policy: Factory(:public_policy))]}
    investigations {[Factory.build(:public_investigation)]}
    studies {[Factory.build(:public_study)]}
    assays {[Factory.build(:public_assay)]}
    data_files {[Factory.build(:public_data_file)]}
    models {[Factory.build(:public_model)]}
    presentations {[Factory.build(:public_presentation)]}
    association :publication_type, factory: :journal
    after_create do |publication|
      publication.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: publication, asset_version: 1)
    end
  end
  
  factory(:publication_with_author, class: Publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    journal 'Journal of Molecular Biology'
    sequence( :published_date) { |n| "2017-10-#{n}" }
    citation 'JMB Oct 2017, 12:234-245'
    # Max publication is compared to a fixture (JSON) so we cannot use the sequence in case this factory is used twice
    publication_authors { [Factory(:publication_author)] }
    abstract 'Amazing insights into the mechanism of TF2'
    editor 'Richling, S. and Baumann, M. and Heuveline, V.'
    booktitle 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016'
    publisher 'Heidelberg University Library, heiBOOKS'
    publication_type_id  Factory(:journal).id
    projects { [Factory(:project)] } # max_project does not use sequence in the title so cannot be reused.
  end
  
  factory(:publication_with_model_and_data_file, class: Publication) do
    title 'A Publication with Model and Data File'
    doi 'https://doi.org/10.5072/abcd'
    projects { [Factory(:min_project)] }
    models {[Factory.build(:teusink_jws_model, policy: Factory(:public_policy))]}
    data_files {[Factory.build(:data_file, policy: Factory(:public_policy))]}
    publication_type_id  Factory(:journal).id
    #association :models, factory: :teusink_jws_model
    #association :data_files, factory: :data_file
  end
  
  factory(:publication_with_date, class: Publication) do
    sequence(:title) { |n| "A Publication #{n}" }
    journal 'Journal of Molecular Biology'
    sequence( :published_date) { |n| "2017-10-#{n}" }
    sequence(:pubmed_id) { |n| n }
    projects { [Factory(:project)] } # max_project does not use sequence in the title so cannot be reused.
    association :contributor, factory: :person
    association :publication_type, factory: :journal
  end
  
  # PublicationAuthor
  factory :publication_author do
    sequence(:first_name) { |n| "Author#{n}" }
    last_name 'Last'
  end
  
  factory :registered_publication_author, parent: :publication_author do
    association :person, factory: :person
  end
  
  # PublicationAuthor
  factory :one_publication_author, parent: :publication_author do
    first_name 'Author_non_registered'
    last_name 'LastNonReg'
  end
  
  factory :one_registered_publication_author, parent: :publication_author do
    association :person,  factory: :person
    first_name 'Author_registered'
    last_name 'LastReg'
  end
end
