# PublicationType
# :journal rely on the existence of the PublicationTypes
Factory.define(:journal, class: PublicationType) do |f|
  f.title 'Journal'
  f.key 'article'
end


Factory.define(:phdthesis, class: PublicationType) do |f|
  f.title 'Phd Thesis'
  f.key 'phdthesis'
end


Factory.define(:inproceedings, class: PublicationType) do |f|
  f.title 'InProceedings'
  f.key 'inproceedings'
end

# Publication
Factory.define(:publication) do |f|
  f.sequence(:title) { |n| "A Publication #{n}" }
  f.sequence(:pubmed_id) { |n| n }
  f.projects { [Factory(:project)] }
  f.association :contributor, factory: :person
  f.association :publication_type, factory: :journal
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:private_publication, class: Publication) do |f|
  f.title 'A Minimal Publication'
  f.doi 'https://doi.org/10.5072/abcd'
  f.projects { [Factory(:project)] }
  f.association :contributor, factory: :person
  f.association :publication_type, factory: :journal
  f.policy { Factory(:private_policy) }
  #f.is_downloadable true
end

Factory.define(:min_publication, class: Publication) do |f|
  f.title 'A Minimal Publication'
  f.doi 'https://doi.org/10.5072/abcd'
  f.projects { [Factory(:min_project)] }
  f.association :publication_type, factory: :journal
end

Factory.define(:max_publication, class: Publication) do |f|
  f.title 'A Maximal Publication'
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.journal 'Journal of Molecular Biology'
  f.published_date '2017-10-10'
  f.doi 'https://doi.org/10.5072/abcd'
  f.pubmed_id '873864488'
  f.citation 'JMB Oct 2017, 12:234-245'
  # Max publication is compared to a fixture (JSON) so we cannot use the sequence in case this factory is used twice
  f.publication_authors { [Factory(:one_publication_author), Factory(:one_registered_publication_author)] }
  f.abstract 'Amazing insights into the mechanism of TF2'
  f.editor 'Richling, S. and Baumann, M. and Heuveline, V.'
  f.booktitle 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016'
  f.publisher 'Heidelberg University Library, heiBOOKS'
  f.publication_type_id  Factory(:journal).id
  f.projects { [Factory(:max_project)] }
  f.events { [Factory.build(:event, policy: Factory(:public_policy))] }
  f.relationships { [Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))] }
  f.association :publication_type, factory: :journal
  f.after_create do |publication|
    publication.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: publication, asset_version: 1)
  end
end

# PublicationAuthor
Factory.define :publication_author do |f|
  f.sequence(:first_name) { |n| "Author#{n}" }
  f.last_name 'Last'
end

Factory.define :registered_publication_author, parent: :publication_author do |f|
  f.association :person
end

# PublicationAuthor
Factory.define :one_publication_author, parent: :publication_author do |f|
  f.first_name 'Author_non_registered'
  f.last_name 'Last'
end

Factory.define :one_registered_publication_author, parent: :publication_author do |f|
  f.association :person
  f.first_name 'Author_registered'
  f.last_name 'Last'
end