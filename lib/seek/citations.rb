require 'citeproc'
require 'csl/styles'
require 'uri'

module Seek
  class Citations
    DEFAULT = 'apa' # This could be a setting one day

    def self.generate(doi, style)
      cp = CiteProc::Processor.new(style: style, format: 'html')
      cp.register(csl(doi).merge(id: :_))
      cp.render(:bibliography, id: :_).last.html_safe
    end

    def self.style_pairs
      Rails.cache.fetch("citation-style-pairs") do
        YAML.load(File.open(style_dictionary_path))
      end
    end

    def self.csl(doi)
      Rails.cache.fetch("citation-#{doi}") do
        resp = RestClient.get(URI.escape("https://doi.org/#{doi}"), accept: 'application/vnd.citationstyles.csl+json')
        JSON.parse(resp)
      end
    end

    def self.generate_style_pairs
      CSL::Style.list.map { |key| [CSL::Style.load(key).title, key] }.sort_by { |s| s[0] }
    end

    def self.style_dictionary_path
      Rails.root.join('config/default_data/csl_styles.yml')
    end
  end
end
