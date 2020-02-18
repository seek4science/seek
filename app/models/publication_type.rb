class PublicationType  < ActiveRecord::Base

  has_many :publications

  #this returns an instance of PublicationType according to one of the publication types
  #if there is not a match nil is returned

  #http://bib-it.sourceforge.net/help/fieldsAndEntryTypes.php#Entries

  def self.for_type type
    keys = { "Journal"=>"article",
             "Book"=>"book",
             "Booklet"=>"booklet",
             "InBook"=>"inbook",
             "InCollection"=>"incollection",
             "InProceedings"=>"inproceedings",
             "Manual"=>"manual",
             "Masters_Thesis"=>"masters_thesis",
             "Misc"=>"misc",
             "Phd_Thesis"=>"phd_thesis",
             "Bachelor_Thesis"=>"bachelorsthesis",
             "Proceedings"=>"proceedings",
             "Tech_Report"=>"tech_report",
             "Unpublished"=>"unpublished" }
    return PublicationType.find_by(key: keys[type])
  end



  def self.get_publication_type_id(bibtex_record)
    str_begin = "@"
    str_end = "{"
    publication_key = bibtex_record.try(:to_s)[/#{str_begin}(.*?)#{str_end}/m, 1]
    unless PublicationType.find_by(key: publication_key).nil?
       return PublicationType.find_by(key: publication_key).id
    else
      return PublicationType.find_by(key: "misc").id
    end
  end


  def self.Journal
    self.for_type('Journal')
  end

  def self.Book
    self.for_type('Book')
  end

  def self.Booklet
    self.for_type('Booklet')
  end
  def self.InBook
    self.for_type('InBook')
  end
  def self.InCollection
    self.for_type('InCollection')
  end
  def self.InProceedings
    self.for_type('InProceedings')
  end
  def self.Manual
    self.for_type('Manual')
  end
  def self.Masters_Thesis
    self.for_type('Masters_Thesis')
  end
  def self.Misc
    self.for_type('Misc')
  end
  def self.Bachelor_Thesis
    self.for_type('Bachelor_Thesis')
  end
  def self.Phd_Thesis
    self.for_type('Phd_Thesis')
  end
  def self.Proceedings
    self.for_type('Proceedings')
  end
  def self.Tech_Report
    self.for_type('Tech_Report')
  end
  def self.Unpublished
    self.for_type('Unpublished')
  end

  def is_journal?
    key == "article"
  end

  def is_book?
    key == 'book'
  end

  def is_booklet?
    key == 'booklet'
  end

  def is_inbook?
    key == 'inbook'
  end

  def is_incollection?
    key == 'incollection'
  end

  def is_inproceedings?
    key == 'inproceedings'
  end

  def is_manual?
    key == 'manual'
  end

  def is_masters_thesis?
    key == 'mastersthesis'
  end

  def is_misc?
    key == 'misc'
  end

  def is_phd_thesis?
    key == 'phdthesis'
  end

  def is_bachelor_thesis?
    key == 'bachelorsthesis'
  end

  def is_proceedings?
    key == 'proceedings'
  end

  def is_tech_report?
    key == 'techreport'
  end

  def is_unpublished?
    key == 'unpublished'
  end

end