require 'active_record_include_bugfixes'
module StrategicEagerLoading
  # Inspired by DataMapper.
  # When you do something like DataFile.all.each {|df| df.policy } you would normally
  # get one query for all the datafiles, and one query on the policy table for each data_file.
  # With this module, you should get one query for DataFile.all, and then the first instance of df.policy
  # will query _all_ the policies for all of the data_files in one go,
  # just like doing DataFile.find(:all, :include => :policy).

  # This behavior nests, so DataFile.all.each {|df| df.policy.permissions.each {|perm| perm.contributor}}
  # should execute 3 queries + 1 query for each contributor_type (contributor is polymorphic). In my dev database it does 8 queries because there are 5 contributor types
  # This can even include some things that you can't get via standard includes. DataFile.all.each {|df| df.policy.permissions.each {|perm| perm.contributor.people if perm.contributor.respond_to?(:people)}}
  # will load the people, which can't be included because contributor is polymorphic. (for my dev db this is about 14 queries in total.)

  #TODO: doesn't behave optimally with 'scoped'. Eg. Project.all.collect {|p| p.work_groups.scoped(:include => :people).collect(&:people)}.flatten does not eager load all of the work_groups for Project.all
  module ActiveRecordExtensions

    def self.included base
      base.class_eval do

        # An items 'strategic_siblings' are all the records that were fetched in the same query that generated it.
        # Each item tracks them, so that when any individual from the set gets an association loaded, it can load it for
        # all of its siblings in a single query.
        attr_accessor :strategic_siblings
        extend ClassMethods
        class << self
          # find_every is one of rails internal finder methods. Many other rails finders eventually resolve to a find_every call, so it is
          # a convenient place to hook in the bit that saves the strategic siblings. Very conveniently, that includes the queries
          # we execute when we do strategic eager loading.
          alias_method_chain :find_every, :strategic_eager_loading
        end
      end
    end

    def reload
      self.strategic_siblings = []
      super
    end

    module ClassMethods

      # All this does is set strategic_siblings for each record returned by find_every
      def find_every_with_strategic_eager_loading *args
        found_records = find_every_without_strategic_eager_loading(*args)
        found_records.each { |r| r.strategic_siblings = found_records.compact } if found_records and found_records.compact.uniq.count > 1
        found_records
      end

    end

  end

  module AssociationProxyExtensions
    def self.included base
      base.class_eval do

        # (This section is not explaining the functionality, it is explaining why I made a specific implementation choice
        #(including the class name in the alias_method_chain's feature name).
        # The reason behind that choice is not clear from reading the code, so here's why.)
        # includes the class name so that calling find_target_without_.. in the superclass of a subclass
        # which also includes these extensions we get a recursive infinite loop (stack overflows of course)
        # Example:
        # HasOneThroughAssociation is a subclass of HasManyThroughAssociation: class HasOneThroughAssociation < HasManyThroughAssociation
        # calling find target on a HasOneThroughAssociation hits find_target_with_strategic_eager_loading.
        # If it decides not to do eager loading, it calls find_target_without.. which calls the original
        # definition of HasOneThroughAssociation#find_target shown here:
        #
        # def find_target
        #   super.first
        # end
        #
        # super calls find_target on HasManyThroughAssociation, which brings us back here, since HasManyThroughAssociation also includes this module.
        # Once again it will decide not to do strategic eager loading, and call find_target_without... since it isn't a call to super, it is resolved as a new
        # method call on self, so it goes back to HasOneThroughAssociation#find_target_without.. which is just the original
        # definition of HasOneThroughAssociation#find_target shown above. Which again will call super, and so on, until the stack overflows.

        underscored_name = name.underscore

        # This is where the main work gets done. find_target is the method the AssociationProxy subclasses call when they need to run to the database.
        # Basically my version just checks to see if it should do strategic eager loading, and then calls one of the methods rails
        # uses for implementing find(:all, :include => :whatever) if it does. Otherwise it delegates to the original version of find_target.
        define_method "find_target_with_strategic_eager_loading_for_#{underscored_name}".to_sym do
          records = proxy_owner.strategic_siblings #records that were generated from the same query as my owner
          if do_strategic_loading?(records)
            ActiveRecord::Base.logger.info "Strategic Loading, parent: #{proxy_owner.class.name.humanize}, child: #{proxy_reflection.name}, via association_type: #{proxy_reflection.macro}"
            proxy_owner.class.send :preload_one_association, records, proxy_reflection.name
            #TODO: GroupMembership.all.each {|gm| gm.person} generates a _ton_ of log statements. I think it is because preload_one_association is not marking person as loaded for instances where person is nil. It isn't causing any additional queries, but it could if the first sibling has no person.

            # the preload_one_association creates a new instance of whatever AssociationProxy subclass is appropriate, and sets it on each record, so
            # we have to get the new association instance it created and take its target, instead of just calling proxy_target
            new_association_proxy = proxy_owner.send(:association_instance_get, proxy_reflection.name)
            new_association_proxy ? new_association_proxy.proxy_target : nil
          else
            #uses __send__ because AssociationProxy overrides send, and sometimes will try and find target, leading us back here, and causing a recursive infinite loop.
            __send__ "find_target_without_strategic_eager_loading_for_#{underscored_name}"
          end
        end

        alias_method_chain :find_target, "strategic_eager_loading_for_#{underscored_name}".to_sym
      end

      def do_strategic_loading?(records)
        # finder_sql doesn't work with include. I think conditions can work with include, but one of our classes has a condition which caused problems.
        !$STRATEGIC_EAGER_LOADING_DISABLED &&
            !records.nil? &&
            !proxy_reflection.options[:finder_sql] &&
            #conditions like '#{self.version}' cause missing method exceptions. They also break standard rails includes.
            !proxy_reflection.options[:conditions]
      end
    end
  end
end

Object.class_eval do
  # Disables strategic eager loading. Queries executed via find_every (like DataFile.all) in
  # the block passed in will store their 'strategic_siblings'. This only prevents eager loads from
  # occuring within the block itself.
  def without_strategic_eager_loading
    old_val = $STRATEGIC_EAGER_LOADING_DISABLED
    $STRATEGIC_EAGER_LOADING_DISABLED = true
    yield
  ensure
    $STRATEGIC_EAGER_LOADING_DISABLED = old_val
  end
end

if Seek::Config.strategic_eager_loading
  ActiveRecord::Associations::AssociationCollection.class_eval do
    # this version of include? executes a query to check if a matching record exists.
    # I think it is better to execute one query to eager load them for everyone.
    # Undefining it gives me AssociationCollection's standard behavior for Array methods, loading
    # the target and passing it on to it. Which triggers the strategic eager loading, if appropriate.
    #undef_method :include?
  end

  ActiveRecord::Base.class_eval { include StrategicEagerLoading::ActiveRecordExtensions }

  # I have to include it into _each_ class instead of a common super class, otherwise I would only be able to wrap around their calls to super.
  [ActiveRecord::Associations::BelongsToAssociation,
   ActiveRecord::Associations::BelongsToPolymorphicAssociation,
   ActiveRecord::Associations::HasOneAssociation,
   ActiveRecord::Associations::HasOneThroughAssociation,
   ActiveRecord::Associations::HasAndBelongsToManyAssociation,
   ActiveRecord::Associations::HasManyAssociation,
   ActiveRecord::Associations::HasManyThroughAssociation
  ].each do |assoc_proxy_class|
    assoc_proxy_class.class_eval { include StrategicEagerLoading::AssociationProxyExtensions }
  end
end