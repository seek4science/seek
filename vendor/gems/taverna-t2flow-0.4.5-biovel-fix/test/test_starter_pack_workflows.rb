# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira

class StarterPackWorkflowsTest < Test::Unit::TestCase
    
  include TestHelper

  def setup
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "996.t2flow"))
    @emboss_tutorial_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "997.t2flow"))
    @biomart_emboss_analysis_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "998.t2flow"))
    @iteration_demo_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "999.t2flow"))
    @interproscan_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "1000.t2flow"))
    @pdb_fetch_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "1001.t2flow"))
    @comic_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "1002.t2flow"))
    @gbseq_wf = T2Flow::Parser.new.parse(File.new(path))
    
    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "1003.t2flow"))
    @pipeline_list_wf = T2Flow::Parser.new.parse(File.new(path))

    path = File.expand_path(File.join(__FILE__, "..", "fixtures", "1004.t2flow"))
    @retrieve_seq_wf = T2Flow::Parser.new.parse(File.new(path))
  end

  def test_emboss_tutorial_wf
    generic_model_test(@emboss_tutorial_wf)

    assert_count(@emboss_tutorial_wf.processors, 15, "@emboss_tutorial_wf.processors")
    assert_count(@emboss_tutorial_wf.sources, 0, "@emboss_tutorial_wf.sources")
    assert_count(@emboss_tutorial_wf.sinks, 3, "@emboss_tutorial_wf.sinks")
    assert_count(@emboss_tutorial_wf.datalinks, 17, "@emboss_tutorial_wf.datalinks")
    assert_count(@emboss_tutorial_wf.coordinations, 0, "@emboss_tutorial_wf.coordinations")
  end

  def test_biomart_emboss_analysis_wf
    generic_model_test(@biomart_emboss_analysis_wf)

    assert_count(@biomart_emboss_analysis_wf.processors, 10, "@biomart_emboss_analysis_wf.processors")
    assert_count(@biomart_emboss_analysis_wf.sources, 0, "@biomart_emboss_analysis_wf.sources")
    assert_count(@biomart_emboss_analysis_wf.sinks, 4, "@biomart_emboss_analysis_wf.sinks")
    assert_count(@biomart_emboss_analysis_wf.datalinks, 17, "@biomart_emboss_analysis_wf.datalinks")
    assert_count(@biomart_emboss_analysis_wf.coordinations, 0, "@biomart_emboss_analysis_wf.coordinations")
  end
  
  def test_iteration_demo_wf
    generic_model_test(@iteration_demo_wf)

    assert_count(@iteration_demo_wf.processors, 8, "@iteration_demo_wf.processors")
    assert_count(@iteration_demo_wf.sources, 0, "@iteration_demo_wf.sources")
    assert_count(@iteration_demo_wf.sinks, 1, "@iteration_demo_wf.sinks")
    assert_count(@iteration_demo_wf.datalinks, 8, "@iteration_demo_wf.datalinks")
    assert_count(@iteration_demo_wf.coordinations, 0, "@iteration_demo_wf.coordinations")
  end

  def test_interproscan_wf
    generic_model_test(@interproscan_wf)

    assert_count(@interproscan_wf.processors, 17, "@interproscan_wf.processors")
    assert_count(@interproscan_wf.sources, 2, "@interproscan_wf.sources")
    assert_count(@interproscan_wf.sinks, 5, "@interproscan_wf.sinks")
    assert_count(@interproscan_wf.datalinks, 23, "@interproscan_wf.datalinks")
    assert_count(@interproscan_wf.coordinations, 2, "@interproscan_wf.coordinations")
  end

  def test_pdb_fetch_wf
    generic_model_test(@pdb_fetch_wf)

    assert_count(@pdb_fetch_wf.processors, 5, "@pdb_fetch_wf.processors")
    assert_count(@pdb_fetch_wf.sources, 1, "@pdb_fetch_wf.sources")
    assert_count(@pdb_fetch_wf.sinks, 1, "@pdb_fetch_wf.sinks")
    assert_count(@pdb_fetch_wf.datalinks, 6, "@pdb_fetch_wf.datalinks")
    assert_count(@pdb_fetch_wf.coordinations, 0, "@pdb_fetch_wf.coordinations")
  end
  
  def test_comic_wf
    generic_model_test(@comic_wf)

    assert_count(@comic_wf.processors, 6, "@comic_wf.processors")
    assert_count(@comic_wf.sources, 0, "@comic_wf.sources")
    assert_count(@comic_wf.sinks, 1, "@comic_wf.sinks")
    assert_count(@comic_wf.datalinks, 7, "@comic_wf.datalinks")
    assert_count(@comic_wf.coordinations, 0, "@comic_wf.coordinations")
  end

  def test_gbseq_wf
    generic_model_test(@gbseq_wf)

    assert_count(@gbseq_wf.processors, 10, "@gbseq_wf.processors")
    assert_count(@gbseq_wf.sources, 0, "@gbseq_wf.sources")
    assert_count(@gbseq_wf.sinks, 8, "@gbseq_wf.sinks")
    assert_count(@gbseq_wf.datalinks, 16, "@gbseq_wf.datalinks")
    assert_count(@gbseq_wf.coordinations, 0, "@gbseq_wf.coordinations")
  end

  def test_pipeline_list_wf
    generic_model_test(@pipeline_list_wf)

    assert_count(@pipeline_list_wf.processors, 8, "@pipeline_list_wf.processors")
    assert_count(@pipeline_list_wf.sources,1, "@pipeline_list_wf.sources")
    assert_count(@pipeline_list_wf.sinks, 1, "@pipeline_list_wf.sinks")
    assert_count(@pipeline_list_wf.datalinks, 9, "@pipeline_list_wf.datalinks")
    assert_count(@pipeline_list_wf.coordinations, 0, "@pipeline_list_wf.coordinations")
  end
  
  def test_retrieve_seq_wf
    generic_model_test(@retrieve_seq_wf)

    assert_count(@retrieve_seq_wf.processors, 4, "@retrieve_seq_wf.processors")
    assert_count(@retrieve_seq_wf.sources, 0, "@retrieve_seq_wf.sources")
    assert_count(@retrieve_seq_wf.sinks, 1, "@retrieve_seq_wf.sinks")
    assert_count(@retrieve_seq_wf.datalinks, 4, "@retrieve_seq_wf.datalinks")
    assert_count(@retrieve_seq_wf.coordinations, 0, "@retrieve_seq_wf.coordinations")
  end

end