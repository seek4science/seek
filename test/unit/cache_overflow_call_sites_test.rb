require 'test_helper'

# Guards the large-item Rails.cache.fetch call sites identified in Step 6 of the Redis/FileStore
# caching plan (#2655) against losing their expires_in - without it, FileStore#cleanup has nothing
# to reap for entries that overflow to disk, and disk usage grows unbounded.
class CacheOverflowCallSitesTest < ActiveSupport::TestCase
  CALL_SITES = {
    'lib/seek/templates/reader.rb' => /Rails\.cache\.fetch\("blob_ss_xml-.*expires_in:/,
    'lib/seek/data/spreadsheet_explorer_representation.rb' =>
      [/Rails\.cache\.fetch\("blob_ss_xml-.*expires_in:/, /Rails\.cache\.fetch\("blob_ss_csv-.*expires_in:/],
    'app/helpers/search_helper.rb' => /Rails\.cache\.fetch\(object\.content_blob\.cache_key, expires_in:/,
    'lib/seek/assets_standard_controller_actions.rb' =>
      /Rails\.cache\.fetch\("spreadsheet-workbook-.*expires_in:/,
    'lib/rightfield/rightfield.rb' =>
      [/Rails\.cache\.fetch\(".*_rf_csv", expires_in:/, /Rails\.cache\.fetch\(".*_rf_rdf", expires_in:/],
    'app/helpers/assets_helper.rb' => /Rails\.cache\.fetch\(".*content_blob\.cache_key.*expires_in:/,
    'lib/seek/renderers/notebook_renderer.rb' => /Rails\.cache\.fetch\("notebook-.*expires_in:/,
    'lib/seek/ontologies/ontology_reader.rb' => /Rails\.cache\.fetch\(cache_key, expires_in:/,
    'lib/ebi/ols_client.rb' => [/Rails\.cache\.fetch\(key, expires_in:/,
                                /Rails\.cache\.fetch\('ebi_ontology_options', expires_in:/]
  }.freeze

  test 'known large-item cache call sites still pass expires_in' do
    CALL_SITES.each do |relative_path, patterns|
      source = File.read(Rails.root.join(relative_path))
      Array(patterns).each do |pattern|
        assert_match(pattern, source,
                     "#{relative_path} no longer matches #{pattern.inspect} - did expires_in get dropped?")
      end
    end
  end
end
