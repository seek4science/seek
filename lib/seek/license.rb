module Seek
  class License < OpenStruct
    NULL_LICENSE = 'notspecified'.freeze
    NULL_LICENSE_TEXT = I18n.t('null_license').freeze

    # overrides values taken from the JSON.
    # Preferable to modifying the JSON file directly which is a definitive source and may be replaced with an updated copy
    private_class_method def self.override_json(json)
      json['notspecified']['title'] = NULL_LICENSE_TEXT
      json['notspecified']['url'] = 'https://choosealicense.com/no-permission/'
      json
    end

    ZENODO = {
      all: JSON.parse(File.read(File.join(Rails.root, 'public', 'zenodo_licenses.json')))
    }

    OPENDEFINITION = {
      all: override_json(JSON.parse(File.read(File.join(Rails.root, 'public', 'od_licenses.json')))).values
    }

    Seek::License::OPENDEFINITION[:all]

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
