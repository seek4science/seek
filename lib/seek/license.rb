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

    private_class_method def self.parse_zenodo(licenses)
                           hash = {}
                           licenses.each do |l|
                             hash[l['id']] = l
                           end
                           hash
                         end

    private_class_method def self.parse_spdx(licenses)
                           hash = {}
                           licenses['licenses'].each do |l|
                             hash[l['licenseId']] = {
                               'title' => l['name'],
                               'id' => l['licenseId'],
                               'url' => (l['seeAlso'] || []).first || l['reference']
                             }
                           end
                           hash
                         end

    private_class_method def self.combine(*licenses)
                           combined = {}
                           licenses.each do |set|
                             set.each { |l| combined[l['id']] ||= l }
                           end
                           combined
                         end

    def self.find(id, source = Seek::License.combined)
      if (license = find_as_hash(id, source))
        new(license)
      end
    end

    def self.find_as_hash(id, source = Seek::License.combined)
      source[id]
    end

    def is_null_license?
      id == NULL_LICENSE
    end

    def self.combined
      @combined ||= open_definition.merge(spdx)
    end

    def self.spdx
      @spdx_licenses ||= parse_spdx(JSON.parse(File.read(File.join(Rails.root, 'public', 'spdx_licenses.json'))))
    end

    def self.open_definition
      @od_licenses ||= override_json(JSON.parse(File.read(File.join(Rails.root, 'public', 'od_licenses.json'))))
    end

    def self.zenodo
      @zenodo_licenses ||= parse_zenodo(JSON.parse(File.read(File.join(Rails.root, 'public', 'zenodo_licenses.json'))))
    end
  end
end
