PUBLICATION_TYPE = [{ title: 'Journal', key: 'article' },
                    { title: 'Book', key: 'book' },
                    { title: 'Booklet', key: 'booklet' },
                    { title: 'InBook', key: 'inbook' },
                    { title: 'InCollection', key: 'incollection' },
                    { title: 'InProceedings', key: 'inproceedings' },
                    { title: 'Manual', key: 'manual' },
                    { title: 'Masters Thesis', key: 'mastersthesis' },
                    { title: 'Misc', key: 'misc' },
                    { title: 'Phd Thesis', key: 'phdthesis' },
                    { title: 'Proceedings', key: 'proceedings' },
                    { title: 'Tech report', key: 'techreport' },
                    { title: 'Unpublished', key: 'unpublished' }

]

PUBLICATION_TYPE.each do |type|
  publication_tpye= PublicationType.find_or_initialize_by(key: type[:key])
  publication_tpye.update_attributes(title: type[:title])
end

puts "Seeded #{PUBLICATION_TYPE.count} publication types"