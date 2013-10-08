# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira

class BogusWorkflowTest < Test::Unit::TestCase
  
  include TestHelper
  
  def setup
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "basic.t2flow"))
    @bogus_basic_wf = T2Flow::Parser.new.parse(File.new(path))
    
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "coordinated.t2flow"))
    @bogus_coordinated_wf = T2Flow::Parser.new.parse(File.new(path))
    
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "linked.t2flow"))
    @bogus_linked_wf = T2Flow::Parser.new.parse(File.new(path))
    
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "nested.t2flow"))
    @bogus_nested_wf = T2Flow::Parser.new.parse(File.new(path))
    
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "processors.t2flow"))
    @bogus_processors_wf = T2Flow::Parser.new.parse(File.new(path))
  end
  
  def test_bogus_basic_wf
    generic_model_test(@bogus_basic_wf)
    
    assert_count(@bogus_basic_wf.processors, 1, "@bogus_basic_wf.processors")
    assert_count(@bogus_basic_wf.sources, 1, "@bogus_basic_wf.sources")
    assert_count(@bogus_basic_wf.sinks, 1, "@bogus_basic_wf.sinks")
    assert_count(@bogus_basic_wf.datalinks, 2, "@bogus_basic_wf.datalinks")
    assert_count(@bogus_basic_wf.coordinations, 0, "@bogus_basic_wf.coordinations")
  end
  
  def test_bogus_coordinated_wf
    generic_model_test(@bogus_coordinated_wf)
    
    assert_count(@bogus_coordinated_wf.processors, 2, "@bogus_coordinated_wf.processors")
    assert_count(@bogus_coordinated_wf.sources, 0, "@bogus_coordinated_wf.sources")
    assert_count(@bogus_coordinated_wf.sinks, 0, "@bogus_coordinated_wf.sinks")
    assert_count(@bogus_coordinated_wf.datalinks, 0, "@bogus_coordinated_wf.datalinks")
    assert_count(@bogus_coordinated_wf.coordinations, 1, "@bogus_coordinated_wf.coordinations")
  end
  
  def test_bogus_linked_wf
    generic_model_test(@bogus_linked_wf)
    
    assert_count(@bogus_linked_wf.processors, 5, "@bogus_linked_wf.processors")
    assert_count(@bogus_linked_wf.sources, 0, "@bogus_linked_wf.sources")
    assert_count(@bogus_linked_wf.sinks, 0, "@bogus_linked_wf.sinks")
    assert_count(@bogus_linked_wf.datalinks, 4, "@bogus_linked_wf.datalinks")
    assert_count(@bogus_linked_wf.coordinations, 0, "@bogus_linked_wf.coordinations")
  end
  
  def test_bogus_nested_wf
    generic_model_test(@bogus_nested_wf)
    
    assert_count(@bogus_nested_wf.processors, 3, "@bogus_nested_wf.processors")
    assert_count(@bogus_nested_wf.sources, 1, "@bogus_nested_wf.sources")
    assert_count(@bogus_nested_wf.sinks, 2, "@bogus_nested_wf.sinks")
    assert_count(@bogus_nested_wf.datalinks, 3, "@bogus_nested_wf.datalinks")
    assert_count(@bogus_nested_wf.coordinations, 1, "@bogus_nested_wf.coordinations")
  end
  
  def test_bogus_processors_wf
    generic_model_test(@bogus_processors_wf)
    
    assert_count(@bogus_processors_wf.processors, 7, "@bogus_processors_wf.processors")
    assert_count(@bogus_processors_wf.sources, 0, "@bogus_processors_wf.sources")
    assert_count(@bogus_processors_wf.sinks, 0, "@bogus_processors_wf.sinks")
    assert_count(@bogus_processors_wf.datalinks, 0, "@bogus_processors_wf.datalinks")
    assert_count(@bogus_processors_wf.coordinations, 0, "@bogus_processors_wf.coordinations")
  end

end