module Seek
  class License < OpenStruct

    LICENSE_ARRAY = JSON.parse(File.read(File.join(Rails.root, 'public', 'licenses.json'))).sort_by { |l| l['title'] }
    DATA_LICENSE_ARRAY = LICENSE_ARRAY.select { |l| l['domain_data'] || l['domain_content'] }

    def self.find(id)
      if (license = self.find_as_hash(id))
        self.new(license)
      end
    end

    def self.find_as_hash(id)
      LICENSE_ARRAY.find { |l| l['id'] == id }
    end

  end
end
