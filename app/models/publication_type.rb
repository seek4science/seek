class PublicationType < ActiveRecord::Base
  has_many :publications


  # Map BibTeX keys → DataCite keys
  BIBTEX_TO_DATACITE_KEY = {
    'article' => 'journalarticle',
    'book' => 'book',
    'booklet' => 'booklet',
    'inbook' => 'bookchapter',
    'incollection' => 'collection',
    'inproceedings' => 'conferencepaper',
    'proceedings' => 'conferenceproceeding',
    'manual' => 'text',
    'misc' => 'other',
    'unpublished' => 'preprint',
    'techreport' => 'report',
    'phdthesis' => 'phdthesis',
    'mastersthesis' => 'mastersthesis',
    'bachelorsthesis' => 'bachelorsthesis'
  }.freeze


  def journalarticle?
    key == 'journalarticle'
  end

  def book?
    key == 'book'
  end

  def booklet?
    key == 'booklet'
  end

  def bookchapter?
    key == 'bookchapter'
  end

  def collection?
    key == 'collection'
  end

  def conferencepaper?
    key == 'conferencepaper'
  end

  def conferenceproceeding?
    key == 'conferenceproceeding'
  end

  def text?
    key == 'text'
  end

  def bachelorsthesis?
    key == 'bachelorsthesis'
  end

  def mastersthesis?
    key == 'mastersthesis'
  end

  def diplomathesis?
    key == 'diplomathesis'
  end

  def phdthesis?
    key == 'phdthesis'
  end

  def dissertation?
    %w[bachelorsthesis mastersthesis diplomathesis phdthesis].include?(key)
  end

  def other?
    key == 'other'
  end

  def preprint?
    key == 'preprint'
  end

  def report?
    key == 'report'
  end

  def audiovisual?
    key == 'audiovisual'
  end

  def award?
    key == 'award'
  end

  def computationalnotebook?
    key == 'computationalnotebook'
  end

  def datapaper?
    key == 'datapaper'
  end

  def dataset?
    key == 'dataset'
  end

  def event?
    key == 'event'
  end

  def image?
    key == 'image'
  end

  def instrument?
    key == 'instrument'
  end

  def interactiveresource?
    key == 'interactiveresource'
  end

  def model?
    key == 'model'
  end

  def outputmanagementplan?
    key == 'outputmanagementplan'
  end

  def peerreview?
    key == 'peerreview'
  end

  def physicalobject?
    key == 'physicalobject'
  end

  def project?
    key == 'project'
  end

  def service?
    key == 'service'
  end

  def software?
    key == 'software'
  end

  def sound?
    key == 'sound'
  end

  def standard?
    key == 'standard'
  end

  def studyregistration?
    key == 'studyregistration'
  end

  def workflow?
    key == 'workflow'
  end

  def projectdeliverable?
    key == 'projectdeliverable'
  end

  
  # Extract publication type from BibTeX record
  def self.get_publication_type_id(bibtex_record)
    # Extract the BibTeX entry type, e.g. article, inbook, misc...
    publication_key = bibtex_record.to_s[/@(.*?)\{/m, 1].to_s.downcase.strip
    datacite_key = BIBTEX_TO_DATACITE_KEY[publication_key] || 'other'
    pub_type = PublicationType.find_by(key: datacite_key)
    return pub_type.id if pub_type
    other_type = PublicationType.find_by(key: 'other')
    other_type&.id
  end

end
