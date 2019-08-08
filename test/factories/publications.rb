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

# Publication
Factory.define(:publication) do |f|
  f.sequence(:title) { |n| "A Publication #{n}" }
  f.sequence(:pubmed_id) { |n| n }
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person
  f.publication_type_id PublicationType.find_by(key: Factory(:journal).key).id
end

Factory.define(:min_publication, class: Publication) do |f|
  f.title 'A Minimal Publication'
  f.doi 'https://doi.org/10.5072/abcd'
  f.projects { [Factory.build(:min_project)] }
  f.publication_type_id PublicationType.find_by(key: Factory(:journal).key).id
end

Factory.define(:max_publication, class: Publication) do |f|
  f.title 'A Maximal Publication'
  f.journal 'Journal of Molecular Biology'
  f.published_date '2017-10-10'
  f.doi 'https://doi.org/10.5072/abcd'
  f.pubmed_id '873864488'
  f.citation 'JMB Oct 2017, 12:234-245'
  f.publication_authors {[Factory(:publication_author), Factory(:publication_author)]}
  f.abstract 'Amazing insights into the mechanism of TF2'
  f.editor 'Richling, S. and Baumann, M. and Heuveline, V.'
  f.booktitle 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016'
  f.publisher 'Heidelberg University Library, heiBOOKS'
  f.publication_type_id PublicationType.find_by(key: Factory(:journal).key).id
  f.projects { [Factory.build(:max_project)] }
  f.events {[Factory.build(:event, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
end

# PublicationAuthor
Factory.define :publication_author do |f|
  f.sequence(:first_name) { |n| "Person#{n}" }
  f.last_name 'Last'
end
