require_relative 'metadata'

module Zenodo
  module ActsAsZenodoDepositable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_zenodo_depositable(&block)
        include Zenodo::ActsAsZenodoDepositable::InstanceMethods

        cattr_accessor :zenodo_depositable_file_getter

        self.zenodo_depositable_file_getter = block
      end

    end

    module InstanceMethods

      def in_zenodo?
        !zenodo_deposition_id.blank?
      end

      def publish_to_zenodo
        if in_zenodo?
          errors.add(:base, "Already deposited in Zenodo, ID: #{zenodo_deposition_id}")
          return false
        end

        client = Zenodo::Client.new(@access_token, Seek::Config.zenodo_url)
        deposition = client.create_deposition(zenodo_metadata)
        deposition_file = deposition.create_file(zenodo_depositable_file)

        update_attribute(:zenodo_deposition_id, deposition.id)
      end

      def zenodo_metadata
        Zenodo::Metadata.from_datacite(datacite_metadata).merge({
          access_right: :closed,
          upload_type: :dataset
        })
      end

      def zenodo_deposition
        if zenodo_deposition_id
          client = Zenodo::Client.new(@access_token, Seek::Config.zenodo_url)

          client.deposition(zenodo_deposition_id)
        end
      end

      private

      def zenodo_depositable_file
        self.class.zenodo_depositable_file_getter.call(self)
      end

    end

  end
end

ActiveRecord::Base.class_eval do
  include Zenodo::ActsAsZenodoDepositable
end
