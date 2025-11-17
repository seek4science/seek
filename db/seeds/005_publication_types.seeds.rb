puts 'Seeding Publication Types...'

yml_path = Rails.root.join('config', 'default_data', 'publication_types.yml')
pubtypes = YAML.load_file(yml_path)

# Build lookup:
#   "Journal Article" → { "title" => "Journal Article", "key" => "journalarticle" }
expected = pubtypes.values.index_by { |data| data["title"] }

# -------------------------------------------------------------------
# Legacy SEEK → DataCite mapping
# -------------------------------------------------------------------
LEGACY_MAPPING = {
  'Journal'        => 'Journal Article',
  'InBook'         => 'Book Chapter',
  'InCollection'   => 'Collection',
  'InProceedings'  => 'Conference Paper',
  'Proceedings'    => 'Conference Proceeding',
  'Manual'         => 'Text',
  'Misc'           => 'Other',
  'Tech report'    => 'Report',
  'Unpublished'    => 'Preprint'
}.freeze

# -------------------------------------------------------------------
# STEP 1 — Migrate legacy types to new DataCite types
# -------------------------------------------------------------------
PublicationType.all.each do |pt|
  legacy_name = pt.title

  if LEGACY_MAPPING.key?(legacy_name)
    new_name = LEGACY_MAPPING[legacy_name]
    target = expected[new_name]

    if target
      puts "Migrating #{legacy_name.inspect} → #{new_name.inspect}"
      pt.update(title: target["title"], key: target["key"])
    else
      puts "WARNING: Missing mapping in YAML for #{new_name.inspect}"
    end
  end
end

# -------------------------------------------------------------------
# STEP 2 — Ensure all DataCite YAML types exist and match
# -------------------------------------------------------------------
expected.values.each do |etype|
  title = etype["title"]
  key   = etype["key"]

  existing = PublicationType.find_by(key: key)

  if existing.nil?
    puts "Creating new type: #{title}"
    PublicationType.create!(title: title, key: key)
  else
    if existing.title != title
      puts "Updating title for #{key}: #{existing.title.inspect} → #{title.inspect}"
      existing.update(title: title)
    end
  end
end

puts 'Publication types synced with publication_types.yml'
