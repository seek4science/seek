module Seek
  module Publishing
    module BatchPublishing
      def self.included(base)
        base.before_filter :set_assets, :only=>[:batch_publishing_preview]
      end

      def batch_publishing_preview
        respond_to do |format|
          format.html { render :template=>"assets/publishing/batch_publishing_preview" }
        end
      end

      def set_assets
        #get the assets that current_user can manage, then take the one that (is not yet published and is publish_authorized)
        @assets = {}
        publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
        publishable_types.each do |klass|
          can_manage_assets = klass.all_authorized_for "manage", current_user
          can_manage_assets = can_manage_assets.select{|a| !a.is_published? && a.publish_authorized?}
          unless can_manage_assets.empty?
            @assets[klass.name] = can_manage_assets
          end
        end
      end
    end
  end
end

