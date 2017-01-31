require 'seek/research_objects/acts_as_snapshottable'
require 'datacite/acts_as_doi_mintable'

class Investigation < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  acts_as_isa
  acts_as_snapshottable
  acts_as_doi_mintable

  attr_accessor :new_link_from_study

  has_many :studies

  has_many :assays,:through=>:studies

  validates :projects,:presence => true

  def state_allows_delete? *args
    studies.empty? && super
  end

  ["data_file","sop","model","publication"].each do |type|
    eval <<-END_EVAL
      def related_#{type}s
        studies.collect{|study| study.send(:related_#{type}s)}.flatten.uniq
      end

      def #{type}_versions
        studies.collect{|study| study.send(:#{type}_versions)}.flatten.uniq
      end
    END_EVAL
  end

  def assets
    related_data_files + related_sops + related_models + related_publications
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.project_ids= self.project_ids
    return new_object
  end

  #includes publications directly related, plus those related to associated assays
  def related_publications
    studies.collect{|s| s.related_publications}.flatten.uniq | publications
  end

end
