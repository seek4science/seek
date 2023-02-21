module Galaxy
  class ToolMap
    include Singleton

    CACHE_KEY = 'galaxy-bio-tools-map'.freeze

    def refresh
      galaxy_instances = Seek::Config.galaxy_tool_sources
      return if galaxy_instances.blank?
      populate(*galaxy_instances)
      Rails.cache.write(CACHE_KEY, map)
    end

    def clear
      RequestStore.delete(CACHE_KEY)
      Rails.cache.delete(CACHE_KEY)
    end

    def lookup(tool_id, strip_version: false)
      tool_id = strip_version(tool_id) if strip_version
      map[tool_id]
    end

    def map
      RequestStore.store[CACHE_KEY] ||= (Rails.cache.read(CACHE_KEY) || {})
    end

    private

    def strip_version(tool_id)
      tool_id.sub(/\/[^\/]+\Z/, '') # Remove version (final / component)
    end

    def populate(*galaxy_instances)
      tool_cache = {}
      galaxy_instances.each do |galaxy_instance|
        sub_map = fetch_galaxy_tools(galaxy_instance, tool_cache)
        map.merge!(sub_map)
      end

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
            tool_id = strip_version(elem['id']) # Remove version (final / component)
            if xref['reftype'] == 'bio.tools'
              biotools_id = xref['value']
              unless tool_cache.key?(biotools_id)
                begin
                  tool_cache[biotools_id] = biotools_client.tool(biotools_id)['name']
                rescue RestClient::NotFound
                  tool_cache[biotools_id] = nil
                rescue StandardError => e
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
