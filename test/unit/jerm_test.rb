require 'test_helper'

class JermTest  < ActiveSupport::TestCase
  
  def test_harverster_factory
    harvester_factory=Jerm::JermHarvesterFactory.new
    assert_not_nil harvester_factory
  end
  
  def test_discover_harvesters
    harvester_factory=Jerm::JermHarvesterFactory.new
    harvesters = harvester_factory.discover_harvesters
    assert !harvesters.empty?
    
    harvesters.each do |h|
      assert h.kind_of?(Jerm::Harvester)
    end
    
  end
end