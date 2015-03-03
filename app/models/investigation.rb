
class Investigation < ActiveRecord::Base

  include Seek::Rdf::RdfGeneration

  acts_as_isa

  attr_accessor :new_link_from_study

  has_many :studies

  has_many :assays,:through=>:studies

  validates :projects,:presence => true

  def state_allows_delete? *args
    studies.empty? && super
  end

  ["data_file","sop","model","publication"].each do |type|
    eval <<-END_EVAL
      def #{type}s
        studies.collect{|study| study.send(:#{type}s)}.flatten.uniq
      end

      def #{type}_versions
        studies.collect{|study| study.send(:#{type}_versions)}.flatten.uniq
      end
    END_EVAL
  end

  def assets
    data_files + sops + models + publications
  end

  def clone_with_associations
    new_object= self.dup
    new_object.policy = self.policy.deep_copy
    new_object.project_ids= self.project_ids
    return new_object
  end

end
