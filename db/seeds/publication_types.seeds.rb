PUBLICATION_TYPE = [{ title: 'Journal', key: 'journal' },
                    { title: 'Book', key: 'book' },
                    { title: 'Booklet', key: 'booklet' },
                    { title: 'InBook', key: 'inbook' },
                    { title: 'InCollection', key: 'incollection' },
                    { title: 'InProceedings', key: 'inproceedings' },
                    { title: 'Manual', key: 'manual' },
                    { title: 'Masters Thesis', key: 'masters_thesis' },
                    { title: 'Misc', key: 'misc' },
                    { title: 'Phd Thesis', key: 'phd_thesis' },
                    { title: 'Proceedings', key: 'proceedings' },
                    { title: 'Tech report', key: 'tech_report' },
                    { title: 'Unpublished', key: 'unpublished' }

]


PUBLICATION_TYPE.each do |type|
  publication_tpye= PublicationType.find_or_initialize_by(key: type[:key])
  publication_tpye.update_attributes(title: type[:title])
end


