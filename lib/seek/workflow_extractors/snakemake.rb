module Seek
  module WorkflowExtractors
    class Snakemake < Base
      def self.ro_crate_metadata
        {
            "@id" => "#snakemake",
            "@type" => "ComputerLanguage",
            "name" => "Snakemake",
            "identifier" => { "@id" => "https://doi.org/10.1093/bioinformatics/bts480" },
            "url" => { "@id" => "https://snakemake.readthedocs.io" }
        }
      end
    end
  end
end
