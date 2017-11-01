# Publication
Factory.define(:publication) do |f|
  f.sequence(:title) { |n| "A Publication #{n}" }
  f.sequence(:pubmed_id) { |n| n }
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person
end

Factory.define(:min_publication, class: Publication) do |f|
  f.title 'A Minimal Publication'
  f.projects { [Factory.build(:min_project)] }
end

Factory.define(:max_publication, class: Publication) do |f|
  f.title 'A Maximal Publication'
  f.journal 'Journal of Molecular Biology'
  f.published_date '2017-10-10'
  f.doi 'http://dx.doi.org/10.5072/abcd'
  f.pubmed_id '873864488'
  f.citation 'JMB Oct 2017, 12:234-245'
  f.publication_authors {[Factory(:publication_author), Factory(:publication_author)]}
  f.abstract 'Amazing insights into the mechanism of TF2'
  f.projects { [Factory.build(:max_project)] }
end

# PublicationAuthor
Factory.define :publication_author do |f|
  f.sequence(:first_name) { |n| "Person#{n}" }
  f.last_name 'Last'
end
