module Seek
  class License < OpenStruct
    NULL_LICENSE = 'notspecified'.freeze

    # overrides values taken from the JSON.
    # Preferable to modifying the JSON file directly which is a definitive source and may be replaced with an updated copy
    private_class_method def self.override_json(json)
      json['notspecified']['title'] = I18n.t('null_license')
      json['notspecified']['url'] = Seek::Help::HelpDictionary.instance.help_link(:null_license)
      json
    end

    private_class_method def self.organize_licenses(licenses)
      category = {}

      category[:all] = licenses
                         .sort_by { |l| l['title'] }
                         .sort_by { |l| l.key?('is_generic') && l['is_generic'] ? 0 : 1 }

      category[:data] = category[:all].select do |l|
        l['domain_data'] ||
          l['domain_content'] ||
          l['id'] == NULL_LICENSE
      end

      category[:software] = category[:all].select do |l|
        (l['domain_software'] || l['id'] == NULL_LICENSE)
      end

      category
    end

    def self.find(id, source = nil)
      if (license = find_as_hash(id, source))
        new(license)
      end
    end

    def self.find_as_hash(id, source = nil)
      source ||= Seek::License.open_definition[:all]
      source.find { |l| l['id'] == id }
    end

    def is_null_license?
      id == NULL_LICENSE
    end

    def self.open_definition
      @od_licenses ||= organize_licenses(override_json(JSON.parse(File.read(File.join(Rails.root, 'public', 'od_licenses.json')))).values)
    end

    def self.zenodo
      @zenodo_licenses ||= organize_licenses(JSON.parse(File.read(File.join(Rails.root, 'public', 'zenodo_licenses.json'))))
    end
  end
end
