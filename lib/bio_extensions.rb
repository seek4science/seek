# reformat the authors
class Bio::MEDLINE
  def reference_with_additional_fields
    reference = reference_without_additional_fields
    reference.published_date = published_date
    reference.citation = citation
    reference.error = error
    reference
  end

  alias_method_chain :reference, :additional_fields

  def citation
    @pubmed['SO']
  end

  def published_date
    published_date = nil
    # first parse published date on PHST - Publication History Status Date
    history_status_date = @pubmed['PHST']
    unless history_status_date.blank?
      # Publication History Status Date: 2012/07/19 [received] 2013/03/05 [accepted] 2013/03/16 [aheadofprint]
      publish_status = ['epublish', 'ppublish', 'aheadofprint', 'entrez,', 'pubmed', 'medline']
      publish_status.each do |status|
        next unless history_status_date.include?(status)
        published_date_index = history_status_date.index(status) - 12
        published_date = history_status_date[published_date_index, 10]
        break
      end
    end
    # if not found then parse on EDAT - Entrez Date, the date the citation was added to PubMed
    published_date = @pubmed['EDAT'][0, 10] if published_date.blank?
    published_date
  end

  def error
    if @pubmed['PMID'].blank?
      'No publication could be found on PubMed with that ID'
    end
  end
end

class Bio::Reference
  def authors_with_reformat
    authors_array = authors_without_reformat
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
  alias_method_chain :authors, :reformat

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
