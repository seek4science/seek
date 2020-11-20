PUBLICATION_TYPE = [{ title: 'Journal', key: 'article' },
                    { title: 'Book', key: 'book' },
                    { title: 'Booklet', key: 'booklet' },
                    { title: 'InBook', key: 'inbook' },
                    { title: 'InCollection', key: 'incollection' },
                    { title: 'InProceedings', key: 'inproceedings' },
                    { title: 'Manual', key: 'manual' },
                    { title: 'Misc', key: 'misc' },
                    { title: 'Phd Thesis', key: 'phdthesis' },
                    { title: 'Masters Thesis', key: 'mastersthesis' },
                    { title: 'Bachelors Thesis', key: 'bachelorsthesis' },
                    { title: 'Proceedings', key: 'proceedings' },
                    { title: 'Tech report', key: 'techreport' },
                    { title: 'Unpublished', key: 'unpublished' }

]
before_n = PublicationType.count
PUBLICATION_TYPE.each do |type|
  publication_type= PublicationType.find_or_initialize_by(key: type[:key])
  publication_type.update_attributes(title: type[:title])
end

seeded_n = PublicationType.count - before_n

puts "Seeded #{seeded_n} publication types" if seeded_n > 0