require 'open-uri'
require 'json'
require 'yaml'

ROOT = File.join(Rails.root, 'public', 'api', 'definitions')
INPUT = 'openapi-v3.yaml'
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
  doc = cache(uri, !pointer.nil?) do
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

# Store block at key, and also parse if it is JSON and store resulting object
def cache(key, as_yaml = false)
  @cache ||= { yaml: {}, raw: {} }
  if block_given?
    @cache[:raw][key] = yield
    @cache[:yaml][key] = YAML.load(@cache[:raw][key]) if as_yaml
  end

  @cache[as_yaml ? :yaml : :raw][key]
end


puts "Resolving API spec..." if VERBOSE
d = dereference({ "$ref" => "#{INPUT}\#/" })
out = File.join(ROOT, OUTPUT)
File.write("#{out}.yaml", d.to_yaml)
File.write("#{out}.json", JSON.pretty_generate(d))
puts "Done - Written to:" if VERBOSE
puts "\t #{out}.yaml" if VERBOSE
puts "\t #{out}.json" if VERBOSE
