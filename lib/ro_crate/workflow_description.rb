module ROCrate
  class WorkflowDescription < ::ROCrate::Workflow
    CWL_LANGUAGE =  {
        "@id" => "#cwl",
        "@type" => "ComputerLanguage",
        "name" => "Common Workflow Language",
        "alternateName" => "CWL",
        "identifier" => { "@id" => "https://w3id.org/cwl/v1.0/" },
        "url" => { "@id" => "https://www.commonwl.org/" }
    }

    properties(%w[programmingLanguage])

    def initialize(*args)
      super.tap do
        self.programming_language = CWL_LANGUAGE
      end
    end
  end
end
