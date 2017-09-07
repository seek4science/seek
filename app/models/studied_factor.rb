class StudiedFactor < ActiveRecord::Base
  include Seek::ExperimentalFactors::ModelConcerns
  include Seek::Rdf::RdfGeneration

  belongs_to :data_file
  has_many :studied_factor_links, before_add: proc { |sf, sfl| sfl.studied_factor = sf }, dependent: :destroy
  alias_attribute :links, :studied_factor_links

  validates :data_file, presence: true

  def range_text
    # TODO: write test
    return start_value unless end_value && end_value != 0
    "#{start_value} to #{end_value}"
  end

  # overridden from Seek::Rdf::Generation - needs to include the datafile in the url
  def rdf_resource
    uri = URI.join(Seek::Config.site_base_host, "data_files/#{data_file.id}/#{self.class.name.tableize}/#{id}").to_s
    RDF::Resource.new(uri)
  end

  # overides that from Seek::RDF::RdfGeneration, as the class dependes upon the measured_item
  def rdf_type_entity_fragment
    measured_item.rdf_type_entity_fragment || 'Factors_studied'
  end
end
