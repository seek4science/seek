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
    
    assert harvesters.include?(Jerm::CosmicHarvester)
    assert harvesters.include?(Jerm::BaCellSysmoHarvester)
    assert harvesters.include?(Jerm::TranslucentHarvester)
    
    harvesters.each do |h|
      superclasses=[]
      c=h
      while !c.superclass.nil? do
        superclasses << c.superclass
        c=c.superclass
      end
      assert superclasses.include?(Jerm::Harvester),"#{h} is not a subclass of Jerm::Harvester"
      
    end
    
  end
end