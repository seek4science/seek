#require 'bio'
require 'bibtex'

namespace :seek_publ_export do

  task(creation_bibtex: :environment) do

    Project.all.each do |one_project|

      warn("In project " + one_project.title)
      bib = BibTeX::Bibliography.new

      one_project.publications.all.order(:published_date).each do |one_publication|

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
        author_raw = one_publication.publication_authors.map { |e| (e.person ? [e.person.last_name+"AAAA", e.person.first_name].join(' ') : [e.last_name+"BBBB", e.first_name].join(' '))
        + [e.last_name+"CCCC", e.first_name].join(' ') }
        authors_publ = one_publication.publication_authors.map { |e| e.person ? [e.person.last_name, e.person.first_name].join(' ') : [e.last_name, e.first_name].join(' ') }

        text_authors = ''
        notFirst = false
        authors_publ.each do |oneAuthor|
          warn('Adding '+oneAuthor.to_s)
          if notFirst
            text_authors += ", "
          end
          notFirst = true
          text_authors += oneAuthor
        end
        warn('Authors raw are ' + author_raw.to_s + ' and non-raw ' + authors_publ.to_s)
        warn('Collated: ' + text_authors)
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
                                   :author => text_authors,
                                   :author_raw => text_authors,
                                   #:author_raw => author_raw,
                                   :publisher => one_publication.publisher,
                                   :title => one_publication.title,
                                   :year => one_publication.published_date.try(:year),
                                   :abstract => one_publication.abstract,
                                   :url => one_publication.url,
                                   :doi => one_publication.doi,
                                   :booktitle => one_publication.booktitle,
                                   :journal =>one_publication.journal,
                                   :citation       => one_publication.citation
                                 })
        oneNewEntry.author = '{'+text_authors+'}'

=begin
        one_publication.publication_authors.each do |oneAuthor|
          if oneAuthor.person.nil?
            oneNewEntry.add(:author => Names.new(Name.new(:first => oneAuthor.first_name, :last => oneAuthor.last_name)))
          elsif
            oneNewEntry.add(:author => Names.new(Name.new(:first => oneAuthor.person.first_name, :last => oneAuthor.person.last_name)))
          end
        end
=end

        #volume       = {40},
        #  number       = {Database issue},
        #  pages        = {D790--D796},

        unless one_publication.pubmed_id.nil?
          oneNewEntry.key = "PMID"+one_publication.pubmed_id.to_s
        end

        bib << oneNewEntry

      end

      unless bib.entries.empty?
        bibtex_file = File.join(Rails.root, 'tmp', 'export_' + one_project.title.parameterize.underscore + '.bibtex')

        file_out = File.open(bibtex_file, "w")

        file_out.write(bib.to_s + "\n\n")

        file_out.close
      end
    end
  end
end
