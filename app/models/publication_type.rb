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


  # Load expected publication types from YAML
  def self.type_registry
    @type_registry ||= begin
                         path = Rails.root.join('config/default_data/publication_types.yml')
                         YAML.load_file(path).values.index_by { |h| h['title'] }
                       end
  end

  def self.for_type(type)
    yaml_entry = type_registry[type]
    return nil unless yaml_entry
    find_by(key: yaml_entry['key'])
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

  begin
    type_registry.each_key do |title|
      define_singleton_method(title.gsub(/\s+/, '')) do
        find_by(key: type_registry[title]['key'])
      end
    end
  rescue => e
    Rails.logger.error("Failed to load publication types: #{e.message}")
  end
end
