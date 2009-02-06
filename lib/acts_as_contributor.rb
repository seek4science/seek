# SysMO: lib/acts_as_contributor.rb
# Original code for this plugin borrowed from myExperiment and tailored for SysMO needs.

# ***************************************************************************************
# * myExperiment: lib/acts_as_contributor.rb
# *
# * Copyright (c) 2007 University of Manchester and the University of Southampton.
# * See license.txt for details.
# ***************************************************************************************

module Mib
  module Acts #:nodoc:
    module Contributor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_contributor
          has_many :assets,
                   :as => :contributor,
                   :order => "resource_type ASC, created_at DESC",
                   :dependent => :destroy

          has_many :policies,
                   :as => :contributor,
                   :order => "created_at DESC",
                   :dependent => :destroy

          has_many :permissions,
                   :as => :contributor,
                   :dependent => :destroy

          class_eval do
            extend Mib::Acts::Contributor::SingletonMethods
          end
          include Mib::Acts::Contributor::InstanceMethods
        end
        
        # TODO add class methods
        # Class methods that are to be shared within all Contributor classes should follow below this line
        #
        #
        # END OF CLASS METHODS
      end

      module SingletonMethods
      end

      module InstanceMethods
        # this method will collect all second-level items belonging to the contributor -
        # i.e. not Assets, but SOPs / spreadsheets / etc.
        def resources
          rtn = []
          
          Asset.find(:all, :conditions => { :contributor_type => self.class.name, :contributor_id => self.id }, :order => "resource_type ASC, resource_id ASC").each do |a|
            rtn << a.resource
          end

          return rtn
        end

        # TODO decide whether this should be kept or direct calls to auth module made across the codebase
        # first method in the authorization chain
        # Mib::Acts::Contributor.authorized? --> Mib::Acts::Contributable.authorized? --> Contribution.authorized? --> Policy.authorized? --> Permission[s].authorized? --> true / false
        #def authorized?(action_name, contributable)
        #  if contributable.kind_of? Mib::Acts::Contributable
        #    return contributable.authorized?(action_name, self)
        #  else
        #    return false
        #  end
        #end

#protected
# TODO
# any methods to follow here

#private
# any methods to follow here
        
      
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Contributor
end
