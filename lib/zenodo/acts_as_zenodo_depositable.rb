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

      def published_in_zenodo?
        !zenodo_record_url.blank?
      end

      def export_to_zenodo(access_token, extra_metadata = {})
        if !has_doi?
          errors.add(:base, "Please generate a DOI before exporting to Zenodo.")
          return false
        end
        if in_zenodo?
          errors.add(:base, "Already deposited in Zenodo, ID: #{zenodo_deposition_id}")
          return false
        end

        extra_metadata = extra_metadata.symbolize_keys
        metadata = zenodo_metadata.merge(extra_metadata)

        #FIXME: this is a quick hack
        metadata[:description] = 'not set' if metadata[:description].blank?

        client = Zenodo::Client.new(access_token, Seek::Config.zenodo_api_url)
        deposition = client.create_deposition({ metadata: metadata.build })
        deposition_file = deposition.create_file(zenodo_depositable_file)

        update_attribute(:zenodo_deposition_id, deposition.id)

        deposition
      end

      def publish_in_zenodo(access_token)
        if !in_zenodo?
          errors.add(:base, "Please export to Zenodo first.")
          return false
        end
        if published_in_zenodo?
          errors.add(:base, "Already published in Zenodo, ID: #{zenodo_deposition_url}")
          return false
        end

        client = Zenodo::Client.new(access_token, Seek::Config.zenodo_api_url)
        deposition = client.deposition(zenodo_deposition_id)

        if deposition.publish
          update_attribute(:zenodo_record_url, deposition.details['record_url'])
        end
      end

      def zenodo_metadata
        metadata = Zenodo::Metadata.new({
          title: title,
          description: description || "",
          creators: related_people.map { |p| {name: "#{p.last_name}, #{p.first_name}"} },
          publication_date: Time.now.strftime("%F"),
          access_right: :closed,
          upload_type: :dataset
        })

        metadata.merge(doi: doi) if respond_to?(:doi) && !doi.blank?
        metadata
      end

      def zenodo_deposition(access_token)
        if zenodo_deposition_id
          client = Zenodo::Client.new(access_token, Seek::Config.zenodo_api_url)

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
