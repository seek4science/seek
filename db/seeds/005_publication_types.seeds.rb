# Load expected publication types from YAML
yml_file = File.join(Rails.root, 'config/default_data/publication_types.yml')
pubtypes = YAML.load_file(yml_file)

# Extract a normalized list of YAML entries
expected = pubtypes.values.map { |x| { title: x['title'], key: x['key'] } }

# Extract database records
actual = PublicationType.all.map { |pt| { title: pt.title, key: pt.key } }

# Compute differences
missing_in_db = expected.reject { |e| actual.include?(e) }
extra_in_db   = actual.reject   { |a| expected.include?(a) }

puts "=== Missing in DB ==="
puts missing_in_db.any? ? missing_in_db.inspect : "None"

puts "\n=== Extra in DB (not in YAML) ==="
puts extra_in_db.any? ? extra_in_db.inspect : "None"

if missing_in_db.empty? && extra_in_db.empty?
  puts "\n✔ All publication types are exactly consistent with YAML."
else
  puts "\n⚠ Inconsistencies found."
end
