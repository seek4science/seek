module Galaxy
  class ToolMap
    def self.instance
      @instance ||= new(Rails.cache)
    end

    def self.refresh
      galaxy_instances = Seek::Config.galaxy_tool_sources
      return if galaxy_instances.blank?
      instance.populate(*galaxy_instances)
    end

    def initialize(cache)
      @cache = cache
    end

    def lookup(tool_id)
      @cache.read(cache_key(tool_id))
    end

    def store(tool_id, tool_data)
      @cache.write(cache_key(tool_id), tool_data)
    end

    def cache_key(tool_id)
      "galaxy-bio-tools-map/#{tool_id}"
    end

    def populate(*galaxy_instances)
      map = {}

      tool_cache = {}
      galaxy_instances.each do |galaxy_instance|
        sub_map = fetch_galaxy_tools(galaxy_instance, tool_cache)
        map.merge!(sub_map)
      end

      map.each { |tool_id, tool_data| store(tool_id, tool_data) }

      map
    end

    def fetch_galaxy_tools(galaxy_instance, tool_cache = {})
      found = {}
      biotools_client = BioTools::Client.new

      begin
        tools = Galaxy::Client.new(galaxy_instance).tools
      rescue RestClient::ExceptionWithResponse => e
        Rails.logger.error("Error fetching Galaxy tools from #{galaxy_instance} - #{e.class.name}:#{e.message}")
        tools = []
      end

      tools.each do |tool|
        (tool['elems'] || []).each do |elem|
          (elem['xrefs'] || []).each do |xref|
            tool_id = elem['id'].sub(/\/[^\/]+\Z/, '') # Remove version (final / component)
            if xref['reftype'] == 'bio.tools'
              biotools_id = xref['value']
              unless tool_cache.key?(biotools_id)
                begin
                  tool_cache[biotools_id] = biotools_client.tool(biotools_id)['name']
                rescue RestClient::ExceptionWithResponse => e
                  Rails.logger.error("Error fetching bio.tools info for #{biotools_id} - #{e.class.name}:#{e.message}")
                end
              end
              if biotools_id && tool_cache[biotools_id]
                found[tool_id] = { bio_tools_id: biotools_id, name: tool_cache[biotools_id] }
              end
            end
          end
        end
      end

      found
    end
  end
end
