class Study < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration
  include Seek::ProjectHierarchies::ItemsProjectsExtension if Seek::Config.project_hierarchy_enabled

  #FIXME: needs to be declared before acts_as_isa, else ProjectAssociation module gets pulled in
  def projects
    investigation.try(:projects) || []
  end

  searchable(:auto_index => false) do
    text :experimentalists
    text :person_responsible do
      person_responsible.try(:name)
    end
  end if Seek::Config.solr_enabled

  acts_as_isa
  acts_as_snapshottable

  attr_accessor :new_link_from_assay

  belongs_to :investigation
  has_many :assays
  belongs_to :person_responsible, :class_name => "Person"

  validates :investigation, :presence => true

  ["data_file","sop","model"].each do |type|
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
    related_data_files + related_sops + related_models + related_publications
  end

  def project_ids
    projects.map(&:id)
  end

  def state_allows_delete? *args
    assays.empty? && super
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy

    return new_object
  end




end
