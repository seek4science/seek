module Seek
  module Rdf
    # Contains some helpful methods for when rdf needs updating due to changes to an associated item. Because the items themselves
    # are not saved, this is required to trigger a job to update the relevant items
    #
    # if there is a Model for a join table (e.g. see AssayOrganism) then you can use:
    #   include Seek::Rdf::ReactToAssociatedChange
    #   update_rdf_on_change :item
    # this will cause ':item' to be updated when the join is saved or destroyed
    #
    # also for has_many, or has_and_belongs_to_many, you can add (e.g)
    #  has_many :people, :before_add=>:update_rdf_on_assocated_change, :before_remove=>:update_rdf_on_associated_change

    module ReactToAssociatedChange
      def self.included(mod)
        mod.class_eval do
          mod.extend(ClassMethods)
        end
      end

      module ClassMethods
        def update_rdf_on_change(*items)
          items = Array(items)
          items.each do |item|
            method = "refresh_#{item}_rdf"
            after_save method.to_sym
            before_destroy method.to_sym

            define_method method do
              i = send(item)
              i.create_rdf_generation_job(true) if !i.nil? && i.respond_to?(:create_rdf_generation_job)
            end
          end
        end
      end

      def update_rdf_on_associated_change(associated_item)
        refresh_rdf
        associated_item.refresh_rdf if associated_item.respond_to?(:refresh_rdf)
      end
    end
  end
end
