#require 'bio'
require 'bibtex'

namespace :seek_publ_export do

  task(creation_bibtex: :environment) do

    Project.all.each do |one_project|

      warn("In project " + one_project.title)
      bib = BibTeX::Bibliography.new

      bibtex_file = File.join(Rails.root, 'tmp', 'export' + one_project.title + '.bibtex')

      file_out = File.open(bibtex_file, "w")

      n = 0

      Publication.all.order(:created_at).each do |one_publication|

        # bib << BibTeX::Entry.new({
        #                            :bibtex_type => :book,
        #                            :key => :rails,
        #                            :address => 'Raleigh, North Carolina',
        #                            :author => 'Ruby, Sam and Thomas, Dave, and Hansson, David Heinemeier',
        #                            :booktitle => 'Agile Web Development with Rails',
        #                            :edition => 'third',
        #                            :keywords => 'ruby, rails',
        #                            :publisher => 'The Pragmatic Bookshelf',
        #                            :series => 'The Facets of Ruby',
        #                            :title => 'Agile Web Development with Rails',
        #                            :year => '2009'
        #                          })
        #

        authors_publ = one_publication.publication_authors.map { |e| e.person ? [e.person.last_name, e.person.first_name].join(', ') : [e.last_name, e.first_name].join(', ') }

=begin
        warn("Found "+one_publication.title+ " " + one_publication.journal+ " " + one_publication.abstract,
             + " " + authors_publ,
             + " " + one_publication.published_date.try(:year).to_s,
             + " " + one_publication.url.to_s)

=end
        # ref = Bio::Reference.new({title: one_publication.title, journal: one_publication.journal, abstract: one_publication.abstract,
        #                          authors: authors_publ,
        #                          year: one_publication.published_date.try(:year),
        #                          url: one_publication.url})
        # warn("Ref is "+ ref.to_s)

        #file_out.write(ref.bibtex + "\n\n")

        oneNewEntry = BibTeX::Entry.new({
                                   :pubmedid => one_publication.pubmed_id.to_s,
                                   :bibtex_type => :article,
                                   :author => authors_publ,
                                   :publisher => one_publication.publisher,
                                   :title => one_publication.title+ " - A ",
                                   :year => one_publication.published_date.try(:year),
                                   :abstract => one_publication.abstract,
                                   :url => one_publication.url,
                                   :doi => one_publication.doi,
                                   :booktitle => one_publication.booktitle
                                 })
        unless one_publication.pubmed_id.nil?
          oneNewEntry.key = "PMID"+one_publication.pubmed_id.to_s
        end

        bib << oneNewEntry

      end

      file_out.write(bib.to_s + "\n\n")
    end
  end
end
