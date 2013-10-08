# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira

module TestHelper
  
  def generic_model_test(model)
    assert !model.nil?, "Model is nil!"

    assert !(model.name.nil? || model.name.strip.empty?), "Model#name is empty/nil!"
    
    assert !(model.main.name.nil? || model.main.name.strip.empty?), "Model#main#name is empty/nil!"
    assert_type(model.main, T2Flow::Dataflow, "Model#main")
    
    # Model
    assert_type(model.dependencies, Array, "Model#dependencies")
    assert_type(model.processors, Array, "Model#processors")
    assert_type(model.sources, Array, "Model#sources")
    assert_type(model.sinks, Array, "Model#sinks")
    assert_type(model.coordinations, Array, "Model#coordinations")
    assert_type(model.datalinks, Array, "Model#datalinks")

    assert_type(model.all_processors, Array, "Model#all_processors")
    assert_type(model.all_sources, Array, "Model#all_sources")
    assert_type(model.all_sinks, Array, "Model#all_sinks")
    assert_type(model.all_coordinations, Array, "Model#all_coordinations")
    assert_type(model.all_datalinks, Array, "Model#all_datalinks")

    assert_type(model.annotations, T2Flow::DataflowAnnotation, "Model#annotations")
    assert_type(model.annotations.titles, Array, "Model#annotations#titles")
    assert_type(model.annotations.authors, Array, "Model#annotations#authors")
    assert_type(model.annotations.descriptions, Array, "Model#annotations#descriptions")
    assert_type(model.annotations.name, String, "Model#annotations#name")

    assert_type(model.beanshells, Array, "Model#beanshells")
    assert_type(model.web_services, Array, "Model#web_services")
    assert_type(model.local_workers, Array, "Model#local_workers")
            
    # ProcessorLinks
    processor_links = model.get_processor_links(model.processors[0])
    assert_type(processor_links, T2Flow::ProcessorLinks, "Model#get_processor_links")
    assert_type(processor_links.sinks, Array, "ProcessorLinks#sinks")
    assert_type(processor_links.sources, Array, "ProcessorLinks#sources")
  end
  
  def assert_type(object, required_class, caption)
    assert object.is_a?(required_class), "#{caption} has an incorrect type: #{object.class.name} -- #{required_class} expected"
  end
  
  def assert_count(list, required_size, caption)
    assert_equal required_size, list.size, "#{caption} has incorrect count: #{list.size} -- #{required_size} expected"
  end
  
end