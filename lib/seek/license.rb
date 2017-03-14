module Seek
  class License < OpenStruct
    NULL_LICENSE = 'notspecified'

    ZENODO = {
      all: JSON.parse(File.read(File.join(Rails.root, 'public', 'zenodo_licenses.json')))
    }

    OPENDEFINITION = {
      all: JSON.parse(File.read(File.join(Rails.root, 'public', 'od_licenses.json'))).values
    }

    [Seek::License::OPENDEFINITION, Seek::License::ZENODO].each do |category|
      category[:all] = category[:all]
                       .sort_by { |l| l['title'] }
                       .sort_by { |l| l.key?('is_generic') && l['is_generic'] ? 1 : 0 }

      category[:data] = category[:all].select do |l|
        l['domain_data'] ||
        l['domain_content'] ||
        l['id'] == NULL_LICENSE
      end
    end

    def self.find(id, source = nil)
      if (license = find_as_hash(id, source))
        new(license)
      end
    end

    def self.find_as_hash(id, source = nil)
      source ||= Seek::License::OPENDEFINITION[:all]
      source.find { |l| l['id'] == id }
    end

    def is_null_license?
      id == NULL_LICENSE
    end
  end
end
