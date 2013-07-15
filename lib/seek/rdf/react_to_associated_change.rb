module Seek
  module Rdf
    module ReactToAssociatedChange
      def self.included(mod)
        mod.class_eval do
          mod.extend(ClassMethods)
        end

      end

      module ClassMethods
        def update_rdf_on_change *items
          items = Array(items)
          items.each do |item|
            method = "refresh_#{item.to_s}_rdf"
            after_save method.to_sym
            before_destroy method.to_sym

            define_method method do
              i = self.send(item)
              i.create_rdf_generation_job(true) if !i.nil? && i.respond_to?(:create_rdf_generation_job)
            end

          end
        end
      end

      def update_rdf_on_associated_change associated_item
        refresh_rdf
        associated_item.refresh_rdf if associated_item.respond_to?(:refresh_rdf)
      end

    end
  end
end