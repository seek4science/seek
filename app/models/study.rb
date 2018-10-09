class Study < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  searchable(:auto_index => false) do
    text :experimentalists
    text :person_responsible do
      person_responsible.try(:name)
    end
  end if Seek::Config.solr_enabled

  belongs_to :investigation
  has_many :projects, through: :investigation

  #FIXME: needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  acts_as_isa
  acts_as_snapshottable

  attr_accessor :new_link_from_assay


  has_many :assays
  belongs_to :person_responsible, :class_name => "Person"

  validates :investigation, presence: { message: "Investigation is blank or invalid" }, projects: true

  enforce_authorization_on_association :investigation, :view

  ["data_file","sop","model","document"].each do |type|
    eval <<-END_EVAL
      def #{type}_versions
        assays.collect{|a| a.send(:#{type}_versions)}.flatten.uniq
      end

      def related_#{type}s
        assays.collect{|a| a.send(:#{type}s)}.flatten.uniq
      end
    END_EVAL
  end

  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end


  def state_allows_delete? *args
    assays.empty? && super
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.publications = publications
    new_object
  end
end
