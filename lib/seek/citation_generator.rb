require 'citeproc'
require 'csl/styles'

module Seek
  class CitationGenerator
    def initialize(doi)
      @doi = doi
    end

    def generate(style)
      cp = CiteProc::Processor.new(style: style, format: 'html')
      cp.register(csl.merge(id: :_))
      cp.render(:bibliography, id: :_).last.html_safe
    end

    private

    def csl
      Rails.cache.fetch("citation-#{@doi}") do
        resp = RestClient.get("https://dx.doi.org/#{@doi}", accept: 'application/vnd.citationstyles.csl+json')
        JSON.parse(resp)
      end
    end
  end
end
