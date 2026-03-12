require 'citeproc'
require 'csl/styles'
require 'uri'

module Seek
  class Citations
    def self.from_doi(doi, style)
      validate_style(style)
      csl = doi_to_csl(doi)
      generate(csl, style)
    end

    def self.from_cff(blob, style)
      validate_style(style)
      csl = cff_to_csl(blob)
      generate(csl, style)
    end

    def self.generate(csl, style)
      cp = CiteProc::Processor.new(style: style, format: 'html')
      cp.register(csl.merge(id: :_))
      cp.render(:bibliography, id: :_).last.html_safe
    end

    def self.style_pairs
      Rails.cache.fetch("citation-style-pairs") do
        YAML.load(File.open(style_dictionary_path))
      end
    end

    def self.valid_styles
      @valid_styles ||= Set.new(style_pairs.map(&:last))
    end

    def self.doi_to_csl(doi)
      Rails.cache.fetch("citation-#{doi}") do
        resp = RestClient.get("https://doi.org/#{Addressable::URI.escape(doi)}", accept: 'application/vnd.citationstyles.csl+json')
        JSON.parse(resp)
      end
    end

    def self.cff_to_csl(blob)
      Rails.cache.fetch("citation-cff-#{blob.cache_key}") do
        cff = ::CFF::File.read(blob.file)
        BibTeX.parse(cff.to_bibtex).to_citeproc.first
      end
    end

    def self.generate_style_pairs
      CSL::Style.list.map { |key| [CSL::Style.load(key).title, key] }.sort_by { |s| s[0] }
    end

    def self.style_dictionary_path
      Rails.root.join('config/default_data/csl_styles.yml')
    end

    def self.valid_style?(style)
      valid_styles.include?(style)
    end

    private

    def self.validate_style(style)
      raise Seek::Citations::InvalidStyleException unless valid_style?(style)
    end
  end
end
