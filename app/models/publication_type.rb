class PublicationType < ActiveRecord::Base
  has_many :publications


  # Map Crossref API type strings → SEEK publication type keys
  CROSSREF_TYPE_TO_KEY = {
    'journal-article' => 'journalarticle',
    'book-chapter' => 'bookchapter',
    'book' => 'book',
    'edited-book' => 'book',
    'monograph' => 'book',
    'proceedings-article' => 'conferencepaper',
    'proceedings' => 'conferenceproceeding',
    'posted-content' => 'preprint',
    'peer-review' => 'peerreview',
    'report' => 'report',
    'dataset' => 'dataset',
    'software' => 'software',
    'standard' => 'standard',
  }.freeze

  # Map DataCite resourceTypeGeneral strings → SEEK publication type keys
  DATACITE_TYPE_TO_KEY = {
    'ConferencePaper' => 'conferencepaper',
    'Dataset' => 'dataset',
    'Software' => 'software',
    'Audiovisual' => 'audiovisual',
    'Image' => 'image',
    'Sound' => 'sound',
    'ComputationalNotebook' => 'computationalnotebook',
    'Workflow' => 'workflow',
    'DataPaper' => 'datapaper',
    'PeerReview' => 'peerreview',
    'Event' => 'event',
    'Award' => 'award',
    'Project' => 'project',
    'Service' => 'service',
    'InteractiveResource' => 'interactiveresource',
    'PhysicalObject' => 'physicalobject',
    'OutputManagementPlan' => 'outputmanagementplan',
    'Standard' => 'standard',
    'StudyRegistration' => 'studyregistration',
    'Collection' => 'collection',
    'Model' => 'model',
    'Instrument' => 'instrument',
    'Text' => 'text',
    'Book' => 'book',
    'BookChapter' => 'bookchapter',
    'Preprint' => 'preprint',
  }.freeze

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

  # Map MEDLINE/PubMed PT field values → SEEK publication type keys.
  # An entry can have multiple PT values (e.g. ["Journal Article", "Clinical Trial"]);
  # the first match in this map wins. Entries with no match fall back to journalarticle
  # because PubMed indexes almost exclusively journal literature.
  # Full type list: https://www.nlm.nih.gov/mesh/pubtypes.html
  PUBMED_TYPE_TO_KEY = {
    'Journal Article' => 'journalarticle',
    'Review' => 'journalarticle',
    'Systematic Review' => 'journalarticle',
    'Meta-Analysis' => 'journalarticle',
    'Clinical Trial' => 'journalarticle',
    'Randomized Controlled Trial' => 'journalarticle',
    'Case Reports' => 'journalarticle',
    'Letter' => 'journalarticle',
    'Editorial' => 'journalarticle',
    'Comment' => 'journalarticle',
    'News' => 'journalarticle',
    'Biography' => 'journalarticle',
    'Historical Article' => 'journalarticle',
    'Retraction of Publication' => 'journalarticle',
    'Preprint' => 'preprint',
    'Dataset' => 'dataset',
    'Software' => 'software',
    'Book' => 'book',
    'Book Chapter' => 'bookchapter',
    'Congress' => 'conferenceproceeding',
    'Technical Report' => 'report',
    'Guideline' => 'report',
    'Government Document' => 'report'
  }.freeze

  # Look up a PublicationType from a raw DOI API type string (Crossref or DataCite)
  def self.from_doi_type(doi_type)
    return nil if doi_type.blank?

    key = CROSSREF_TYPE_TO_KEY[doi_type] || DATACITE_TYPE_TO_KEY[doi_type]
    find_by(key: key) if key
  end

  # Look up a PublicationType from an array of MEDLINE PT field values.
  # Returns the first specific match, or journalarticle as a fallback (since
  # PubMed indexes almost exclusively journal literature).
  def self.from_pubmed_types(pub_types)
    return nil if pub_types.blank?

    key = pub_types.filter_map { |t| PUBMED_TYPE_TO_KEY[t] }.first
    key ||= 'journalarticle'
    find_by(key: key)
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
