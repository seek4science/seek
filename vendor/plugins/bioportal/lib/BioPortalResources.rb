class BioPortalResources
    attr_accessor :base_url, :uri, :path, :params
    
    APPLICATION_ID = "4ea81d74-8960-4525-810b-fa1baab576ff"

    @@tokens = { "%ONT%" => :ontology_id, "%ONT_VIRTUAL%" => :ontology_virtual_id, "%CONC%" => :concept_id,
                 "%VIEW%" => :view_id, "%USR%" => :user_id, "%START%" => :ontology_id_start,
                 "%END%" => :ontology_id_end, "%VER1%" => :ontology_version1, "%VER2%" => :ontology_version2 }
                 
    def initialize(params = nil)
      if params
        @params = params.clone
      end
      @uri_base_url = $REST_URL.clone
      @uri = @uri_base_url.clone
    end
    
    def generate_uri
      if @params
        @@tokens.each do |token, symbol|
          if @uri.include?(token)
            @uri.gsub!(token, CGI.escape(@params[symbol].to_s))
          end
        end
      end
      
      param_start = @uri.include?("?") ? "&" : "?"
      @uri << param_start + "applicationid=#{APPLICATION_ID}"
      
      return @uri
    end
    
    class Ontology < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/%ONT%"
      end
    end
    
    class CreateOntology < BioPortalResources
      def initialize
        super
        @uri << "/ontologies/"
      end
    end
    
    class UpdateOntology < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/%ONT%"
      end
    end
    
    class DownloadOntology < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/download/%ONT%"
      end
    end
    
    class Ontologies < BioPortalResources
      def initialize
        super
        @uri << "/ontologies/"
      end
    end
    
    class ActiveOntologies < BioPortalResources
      def initialize
        super
        @uri << "/ontologies/active/"
      end
    end

    class OntologyVersions < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/versions/%ONT_VIRTUAL%"
      end
    end

    class OntologyMetrics < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/metrics/%ONT%"
      end
    end
    
    class Categories < BioPortalResources
      def initialize
        super
        @uri << "/categories/"
      end
    end
    
    class Groups < BioPortalResources
      def initialize
        super
        @uri << "/groups"
      end
    end
    
    class Concept < BioPortalResources
      def initialize(params, max_children = nil, light = nil)
        super(params)
        @uri << "/concepts/%ONT%/?conceptid=%CONC%"
        if max_children
          @uri << "&maxnumchildren=" + max_children.to_s
        end
        if light
          @uri << "&light=true"
        end
      end
    end

    class PathToRoot < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/path/%ONT%/?source=%CONC%&target=root&maxnumchildren=1000"
      end
    end
    
    class View < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/%VIEW%"
      end
    end
    
    class ViewVersions < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/views/versions/%ONT%"
      end
    end
    
    class LatestOntology < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/virtual/ontology/%ONT_VIRTUAL%"
      end
    end
    
    class Users < BioPortalResources
      def initialize
        super
        @uri << "/users"
      end
    end
    
    class User < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/users/%USR%"
      end
    end
    
    class CreateUser < BioPortalResources
      def initialize
        super
        @uri << "/users/"
      end
    end
    
    class UpdateUser < BioPortalResources
      def initialize
        super
        @uri << "/users/"
      end
    end
    
    class Auth < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/auth?username=#{params[:username]}&password=#{params[:password]}"
      end
    end
    
    class ParseOntology < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/parse/%ONT%"
      end
    end
    
    class ParseOntologies < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/ontologies/parsebatch/%START%/%END%"
      end
    end
    
    class Diffs < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/diffs/%ONT%"
      end
    end
    
    class DownloadDiff < BioPortalResources
      def initialize(params)
        super(params)
        @uri << "/diffs/download/%VER1%/%VER2%"
      end
    end
end