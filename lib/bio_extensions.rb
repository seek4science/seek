# reformat the authors
module BioMedlineExtensions
  def reference
    reference = super
    reference.published_date = published_date
    reference.citation = citation
    reference.error = error
    reference
  end

  def citation
    @pubmed['SO']
  end

  def published_date
    published_date = nil
    pub_date_array = nil
    published_date_dp = @pubmed['DP'].delete!("\n")

    # first check date on DP
    if !published_date_dp.blank? && published_date_dp.split(" ").count == 3
      published_date = Date::strptime(published_date_dp, "%Y %b %d")
    else
      #first parse published date on PHST - Publication History Status Date
      history_status_date = @pubmed['PHST']
      unless history_status_date.blank?
        # Publication History Status Date: "2018/07/19 00:00 [received]\n2018/11/02 00:00 [accepted]\n2018/11/17 06:00 [entrez]\n2018/11/18 06:00 [pubmed]\n2018/11/18 06:00 [medline]\n"
        publish_status = ['epublish', 'ppublish', 'aheadofprint', 'medline', 'entrez', 'pubmed']

        pub_date_array = history_status_date.split("\n").map do |pair|
          k, v = pair.split(' ')[2][1..-2], pair.split(' ')[0]
          {k => v}
        end

        pub_date_array.each do |date|
          next unless publish_status.include?(date.keys[0])
          published_date = Date::strptime(date[date.keys[0]], "%Y/%m/%d")
          break
        end
      end

      # if not found then parse on EDAT - Entrez Date, the date the citation was added to PubMed
      if !@pubmed['EDAT'].blank? && published_date.blank?
        published_date = Date::strptime(@pubmed['EDAT'].split(" ")[0], "%Y/%m/%d")
      end
    end
    published_date
  end

  def error
    if @pubmed['PMID'].blank?
      'No publication could be found on PubMed with that ID'
    end
  end
end

module BioReferenceExtensions
  def authors
    authors_array = super
    reformat_authors = []
    authors_array.each do |author|
      # Petzold, A.
      last_name, first_name = author.split(',')
      last_name.strip!
      first_name.strip!
      reformat_authors << Author.new(first_name, last_name)
    end
    reformat_authors
  end

  attr_accessor :published_date, :citation, :error
end

class Author
  attr_accessor :first_name, :last_name

  def initialize(first, last)
    self.first_name = first
    self.last_name = last
  end

  def name
    first_name + ' ' + last_name
  end

  alias_method :full_name, :name

  def to_s
    last_name + ', ' + first_name
  end
end

Bio::MEDLINE.class_eval do
  prepend BioMedlineExtensions
end

Bio::Reference.class_eval do
  prepend BioReferenceExtensions
end
