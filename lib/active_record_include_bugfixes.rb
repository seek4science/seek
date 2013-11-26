module ActiveRecordIncludeBugfixes

  def self.included base
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    # The bug:
    # has many through associations that specify a source type lose the type based restriction
    # if you first include the through records' association. It also resets the included through association.
    #
    #
    # Example:
    #    assays = Assay.find(:all, :include => [:assay_assets, :sop_masters])
    #    assays.map(&:sop_masters).flatten # this will include data_files and models as well as sops
    #    assays.first.assay_assets.loaded? # this will return false
    #
    # If you reverse the order the to [:sop_masters, :assay_assets] then there is no problem.
    #
    # The cause:
    # This happens because while it is preloading :sop_masters, it calls preload_association to load
    # the assay_assets, with a condition to restrict it to the subset of the assay_assets that point to a sop.
    # Then since it has only loaded a subset, it resets each of the assay_asset proxies afterward. But if the association has already
    # been loaded, preload_has_many_association (called by preload_association) will return without doing
    # anything, which leaves _whole_ set of assay_assets loaded, not just the subset which points to a sop.
    # Then the assay_assets get reset afterward.
    #
    # The fix:
    # if the reflection has a source type, I move the through models existing proxy targets to a hash map, leaving the proxies empty as if :assay_assets had not been
    # loaded. Then preloading the sop_masters will proceed correctly. Afterwards I put the assay_assets back how I found them.
    def preload_through_records(records, reflection, through_association)
      if reflection.options[:source_type]
        records.compact!
        through_proxies = {}
        records.each do |r|
          proxy = r.send(through_association)
          through_proxies[r.object_id] = proxy.proxy_target
          proxy.reset
        end
        through_records = super
        records.each do |r|
          proxy = r.send(through_association)
          if old_target = through_proxies[r.object_id]
            proxy.target = old_target
          else
            proxy.reset
          end
        end
        through_records
      else
        super
      end
    end


    # The bug:
    # If you have a has_many :through association, and the source association on the through model has nil's, preload_has_many_association will
    # put those nil's in the preloaded association. But if you load the has_many :through without preloading it, you don't get the nils.
    #
    # Example:
    # class WorkGroup
    #   has_many :group_memberships
    #   has_many :people, :through => :group_memberships
    # end
    # class GroupMembership
    #   belongs_to :group_membership
    #   belongs_to :person
    # end
    #
    # My Database has some group memberships that have person == nil and work_group != nil
    # WorkGroup.all.map(&:people).flatten.count != WorkGroup.find(:all, :include => :people).map(&:people).flatten.count
    # .. this returns true, when it should return false
    #
    # The fix:
    # I've copied the whole preload_has_many_association method, just to remove nils from the records passed to add_preloaded_records_to_collection. It's an
    # ugly fix. Because I copied the method, if rails is updated with a new implementation of this method, this will wipe out their changes.
    # Because of that, I check the rails version, and raise an exception if it has changed, to force us to check this method when we upgrade.
    def preload_has_many_association(records, reflection, preload_options={})
      #raise "Updated version of rails, please check that the patch in StrategicEagerLoading::ActiveRecordIncludeBugfixes is still correct" unless Rails.version == "2.3.8" || Rails.env == 'production'

      return if records.first.send(reflection.name).loaded?
      options = reflection.options

      primary_key_name = reflection.through_reflection_primary_key_name
      id_to_record_map, ids = construct_id_map(records, primary_key_name || reflection.options[:primary_key])
      records.each {|record| record.send(reflection.name).loaded}

      if options[:through]
        through_records = preload_through_records(records, reflection, options[:through])
        through_reflection = reflections[options[:through]]
        unless through_records.empty?
          source = reflection.source_reflection.name
          through_records.first.class.preload_associations(through_records, source, options)
          through_records.each do |through_record|
            through_record_id = through_record[reflection.through_reflection_primary_key].to_s
            #MY CHANGES
              loaded_records = through_record.send(source)
              # depending on the source associations type, the loaded records might be a single record or a set. add_preloaded_records_to_collection will accept either.
              loaded_records = loaded_records.nil? ? [] : [loaded_records].flatten.compact
              #END OF MY CHANGES
            add_preloaded_records_to_collection(id_to_record_map[through_record_id], reflection.name, loaded_records)
          end
        end

      else
        set_association_collection_records(id_to_record_map, reflection.name, find_associated_records(ids, reflection, preload_options),
                                           reflection.primary_key_name)
      end
    end

  end
end

ActiveRecord::Base.class_eval { include ActiveRecordIncludeBugfixes }