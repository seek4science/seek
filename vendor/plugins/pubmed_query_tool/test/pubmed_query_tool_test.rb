require 'test_helper'

class PubmedQueryToolTest < ActiveSupport::TestCase
  test "can fetch single" do
    p = PubmedQuery.new("pubmed-query-tool-test","")
    result = delay_query{p.fetch(1)}
    assert !result.nil?
    assert_equal "Biochem Med", result.journal
    assert_equal "Formate assay in body fluids: application in methanol poisoning.", result.title
    assert_equal 4, result.authors.size
    assert_equal "Makar", result.authors.first.last_name
    assert_equal "Sun, 01 Jun 1975".to_date, result.date_published
  end
  
  test "can fetch multiple" do
    p = PubmedQuery.new("pubmed-query-tool-test","")
    result = delay_query{p.fetch_many([1,10000])}
    assert_equal 2, result.size
    result = result.last
    assert_equal "10000", result.pmid
    assert_equal 2002, result.abstract.size
  end
  
  #TODO: this
  test "can search" do
    assert true
  end
  
  private
  
  #A method to delay each query by 0.5 seconds to stop it flooding the API
  def delay_query
    @time ||= Time.now
    delay = 0.5
    wait_time = delay - (Time.now - @time).to_f
    sleep(wait_time) unless wait_time <= 0
    x = yield
    @time = Time.now
    return x
  end
end
