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
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person
  f.association :publication_type, factory: :journal
end

Factory.define(:min_publication, class: Publication) do |f|
  f.title 'A Minimal Publication'
  f.doi 'https://doi.org/10.5072/abcd'
  f.projects { [Factory.build(:min_project)] }
  f.association :publication_type, factory: :journal
end

Factory.define(:max_publication, class: Publication) do |f|
  f.title 'A Maximal Publication'
  f.journal 'Journal of Molecular Biology'
  f.published_date '2017-10-10'
  f.doi 'https://doi.org/10.5072/abcd'
  f.pubmed_id '873864488'
  f.citation 'JMB Oct 2017, 12:234-245'
  f.publication_authors {[Factory(:publication_author), Factory(:registered_publication_author)]}
  f.abstract 'Amazing insights into the mechanism of TF2'
  f.editor 'Richling, S. and Baumann, M. and Heuveline, V.'
  f.booktitle 'Proceedings of the 3rd bwHPC-Symposium: Heidelberg 2016'
  f.publisher 'Heidelberg University Library, heiBOOKS'
  f.publication_type_id  Factory(:journal).id
  f.projects { [Factory.build(:max_project)] }
  f.events {[Factory.build(:event, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.association :publication_type, factory: :journal
end

# PublicationAuthor
Factory.define :publication_author do |f|
  f.sequence(:first_name) { |n| "Author#{n}" }
  f.last_name 'Last'
end

Factory.define :registered_publication_author, parent: :publication_author do |f|
  f.association :person
end
