
class Study < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  acts_as_isa

  attr_accessor :new_link_from_assay

  belongs_to :investigation



  def projects
    investigation.try(:projects) || []
  end

  def project_ids
    projects.map(&:id)
  end

  acts_as_authorized

  has_many :assays

  belongs_to :person_responsible, :class_name => "Person"


  validates_presence_of :investigation

  searchable(:ignore_attribute_changes_of=>[:updated_at]) do
    text :description,:title, :experimentalists
    text :contributor do
      [contributor.try(:person).try(:name),person_responsible.try(:name)]
    end
  end if Seek::Config.solr_enabled

  #FIXME: see comment in Assay about reversing these
  ["data_file","sop","model","publication"].each do |type|
    eval <<-END_EVAL
      def #{type}_masters
        assays.collect{|a| a.send(:#{type}_masters)}.flatten.uniq
      end

      def #{type}s
        assays.collect{|a| a.send(:#{type}s)}.flatten.uniq
      end

      #related items hash will use data_file_masters instead of data_files, etc. (sops, models)
      def related_#{type.pluralize}
        #{type}_masters
      end
    END_EVAL
  end

  def state_allows_delete? *args
    assays.empty? && super
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.scale_ids = self.scale_ids

    return new_object
  end

end
