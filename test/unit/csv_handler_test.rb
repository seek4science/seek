require 'test_helper'

class CSVHandlerTest < ActiveSupport::TestCase

  test "resolve parameter keys" do
    csv = %!,,"a","b","c","d","e"\n,,1,2,3,4,5!
    matched_csv,matched_keys = Seek::CSVHandler.resolve_model_parameter_keys ["a","c"],csv
    assert_equal ["a","c"],matched_keys
    assert_equal %!a,c\n1,3\n!,matched_csv

    csv = %!,,,"a","b","c","d","e"\n,,7,1,2,3,4,5\n,,,1.0,2,8,9.0,5,6,7!
    matched_csv,matched_keys = Seek::CSVHandler.resolve_model_parameter_keys ["a","c","d","z"],csv
    assert_equal ["a","c","d"],matched_keys
    assert_equal %!a,c,d\n1,3,4\n1.0,8,9.0\n!,matched_csv
  end

end