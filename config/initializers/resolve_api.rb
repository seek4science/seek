require 'open-uri'
require 'json'
require 'yaml'

ROOT = File.join(Rails.root, 'public', 'api', 'definitions')
INPUT = 'openapi-v3.yml'
OUTPUT = 'openapi-v3-resolved'
ALLOW_INTERNAL_REFS = true # If true, don't replace internal references i.e. "#/definitions/something"
VERBOSE = false

# Resolves and replaces $refs
def dereference(obj)
  if obj.is_a?(Hash)
    if obj.key?('$ref')
      uri, pointer = obj['$ref'].split('#')
      if uri == ''
        return obj if ALLOW_INTERNAL_REFS
        uri = INPUT
      end
      return dereference(resolve(uri, pointer))
    else
      return obj.transform_values do |value|
        dereference(value)
      end
    end
  elsif obj.is_a?(Array)
    return obj.map { |i| dereference(i) }
  else
    return obj
  end
end

def resolve(uri, pointer)
  type = :raw
  type = :yaml if uri.end_with?('.yml') || uri.end_with?('.yaml') || !pointer.nil?
  type = :json if uri.end_with?('.json')
  doc = cache(uri, type) do
    if uri.start_with?('http')
      open(uri).read
    else
      File.read(File.join(ROOT, uri))
    end
  end

  pointer ? dig(doc, pointer) : doc
end

# Dig out a value from the hash via a /path/like/this
def dig(hash, path)
  keys = path.sub(/\A\//, '').split('/')
  keys.length > 0 ? hash.dig(*keys) : hash
end

# Store block at key, and also parse if it is JSON/YAML and store resulting object
def cache(key, type = :raw)
  @cache ||= { json: {}, raw: {}, yaml: {} }
  if block_given?
    @cache[:raw][key] = yield
    @cache[:json][key] = JSON.parse(@cache[:raw][key]) if type == :json
    @cache[:yaml][key] = YAML.unsafe_load(@cache[:raw][key]) if type == :yaml
  end

  @cache[type][key]
end


puts "Resolving API spec..." if VERBOSE

begin
  d = dereference({ "$ref" => "#{INPUT}\#/" })
  out = File.join(ROOT, OUTPUT)
  File.write("#{out}.yaml", d.to_yaml)
  File.write("#{out}.json", JSON.pretty_generate(d))
rescue StandardError=>exception
  puts "Error resolving api"
  Rails.logger.error "Error resolving api"
  Rails.logger.error exception.message
  Rails.logger.error exception.backtrace
end


puts "Done - Written to:" if VERBOSE
puts "\t #{out}.yml" if VERBOSE
puts "\t #{out}.json" if VERBOSE
