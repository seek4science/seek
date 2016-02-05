module Seek
  class License < OpenStruct

    NULL_LICENSE = 'notspecified'

    LICENSE_ARRAY = JSON.parse(File.read(File.join(Rails.root, 'public', 'licenses.json'))).
        sort_by { |l| l['title'] }.
        sort_by { |l| l.has_key?('is_generic') && l['is_generic'] ? 1 : 0 }

    DATA_LICENSE_ARRAY = LICENSE_ARRAY.select do |l|
      l['domain_data'] ||
      l['domain_content'] ||
      l['id'] == NULL_LICENSE
    end

    def self.find(id)
      if (license = self.find_as_hash(id))
        self.new(license)
      end
    end

    def self.find_as_hash(id)
      LICENSE_ARRAY.find { |l| l['id'] == id }
    end

    def is_null_license?
      id == NULL_LICENSE
    end

  end
end
