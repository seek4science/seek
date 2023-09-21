module Seek
  class License < OpenStruct
    NULL_LICENSE = 'notspecified'.freeze

    private_class_method def self.parse_od(licenses)
                           # overrides values taken from the JSON.
                           # Preferable to modifying the JSON file directly which is a definitive source and may be replaced with an updated copy
                           licenses[NULL_LICENSE]['title'] = I18n.t('null_license')
                           licenses[NULL_LICENSE]['url'] = Seek::Help::HelpDictionary.instance.help_link(:null_license)
                           licenses.each_value do |license|
                             license['urls'] = [license['url']].compact_blank
                           end
                           licenses
                         end

    private_class_method def self.parse_spdx(licenses)
                           hash = {}
                           licenses['licenses'].each do |l|
                             hash[l['licenseId']] = {
                               'title' => l['name'],
                               'id' => l['licenseId'],
                               'url' => l['reference'].chomp('.html'),
                               'urls' => [l['reference'].chomp('.html'), l['reference'], l['detailsUrl'], *l['seeAlso']].compact_blank
                             }
                           end
                           hash
                         end

    private_class_method def self.parse_zenodo(licenses)
                           hash = {}
                           licenses.each do |l|
                             hash[l['id']] = l
                           end
                           hash
                         end

    def self.find(id, source = Seek::License.combined)
      if (license = find_as_hash(id, source))
        new(license)
      end
    end

    def self.uri_to_id(uri)
      uri_map[uri]
    end

    def self.find_as_hash(id, source = Seek::License.combined)
      source[id]
    end

    def is_null_license?
      id == NULL_LICENSE
    end

    def self.combined
      @combined ||= open_definition.merge(spdx) do |key, od_license, spdx_license|
        spdx_license['urls'] |= od_license['urls'] # Merge together alternate URLs
        spdx_license
      end
    end

    def self.spdx
      @spdx_licenses ||= parse_spdx(JSON.parse(File.read(File.join(Rails.root, 'public', 'spdx_licenses.json'))))
    end

    def self.open_definition
      @od_licenses ||= parse_od(JSON.parse(File.read(File.join(Rails.root, 'public', 'od_licenses.json'))))
    end

    def self.zenodo
      @zenodo_licenses ||= parse_zenodo(JSON.parse(File.read(File.join(Rails.root, 'public', 'zenodo_licenses.json'))))
    end

    def self.uri_map
      return @uri_map if @uri_map
      @uri_map = {}
      combined.each do |id, license|
        (license['urls'] || []).each do |url|
          @uri_map[url] ||= id
        end
      end
      @uri_map
    end
  end
end
