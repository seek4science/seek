# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira

module T2Flow
  
  # This class enables you to write the script will will be used by dot
  # (which is part of GraphViz[http://www.graphviz.org/Download.php])
  # to generate the image showing the structure of a given model.
  # To get started quickly, you could try:
  #   out_file = File.new("path/to/file/you/want/the/dot/script/to/be/written", "w+")
  #   workflow = File.new("path/to/workflow/file", "r").read
  #   model = T2Flow::Parser.new.parse(workflow)
  #   T2Flow::Dot.new.write_dot(out_file, model)
  #   `dot -Tpng -o"path/to/the/output/image" #{out_file.path}`
  class Dot

    @@processor_colours = {
      'apiconsumer' => '#98fb98',
      'beanshell' => '#deb887',
      'biomart' => '#d1eeee',
      'localworker' => '#d15fee',
      'biomobywsdl' => '#ffb90f',
      'biomoby' => '#ffb90f',
      'biomobyobject' => '#ffd700',
      'biomobyparser' => '#ffffff',
      'inferno' => 'violetred1',
      'notification' => 'mediumorchid2',
      'rdfgenerator' => 'purple',
      'rserv' => 'lightgoldenrodyellow',
      'seqhound' => '#836fff',
      'soaplabwsdl' => '#fafad2',
      'soaplab' => '#fafad2',
      'stringconstant' => '#b0c4de',
      'talisman' => 'plum2',
      'bsf' => 'burlywood2',
      'abstractprocessor' => 'lightgoldenrodyellow',
      'xmlsplitter' => '#ab92ea',
      'rshell' => '#648faa',
      'arbitrarywsdl' => 'darkolivegreen3',
      'wsdl' => '#a2cd5a',
      'workflow' => 'crimson',
      'rest' => '#7aafff',
      'xpath' => '#e6ff5e',
      'externaltool' => '#f28c55',
      'spreadsheet' => '#40e0d0',
      'dataflow' => '#ffc0cb',
      'rshell' => '#648faa',
    }
    
    @@fill_colours = %w{white aliceblue antiquewhite beige}
    
    @@ranksep = '0.22'
    @@nodesep = '0.05'
    
    # Creates a new dot object for interaction.
    def initialize
      # @port_style IS CURRENTLY UNUSED. IGNORE!!!
      @port_style = 'none' # 'all', 'bound' or 'none'
    end
    
    # Writes to the given stream (File, StringIO, etc) the script to generate
    # the image showing the internals of the given workflow model.  
    # === Usage
    #   stream = File.new("path/to/file/you/want/the/dot/script/to/be/written", "w+")
    #   workflow = .......
    #   model = T2Flow::Parser.new.parse(workflow)
    #   T2Flow::Dot.new.write_dot(stream, model)
    def write_dot(stream, model)
      @t2flow_model = model
      stream.puts 'digraph t2flow_graph {'
      stream.puts ' graph ['
      stream.puts '  style=""'
      stream.puts '  labeljust="left"'
      stream.puts '  clusterrank="local"'
      stream.puts "  ranksep=\"#@@ranksep\""
      stream.puts "  nodesep=\"#@@nodesep\""
      stream.puts ' ]'
      stream.puts
      stream.puts ' node ['
      stream.puts '  fontname="Helvetica",'
      stream.puts '  fontsize="10",'
      stream.puts '  fontcolor="black", '
      stream.puts '  shape="box",'
      stream.puts '  height="0",'
      stream.puts '  width="0",'
      stream.puts '  color="black",'
      stream.puts '  fillcolor="lightgoldenrodyellow",'
      stream.puts '  style="filled"'
      stream.puts ' ];'
      stream.puts
      stream.puts ' edge ['
      stream.puts '  fontname="Helvetica",'
      stream.puts '  fontsize="8",'
      stream.puts '  fontcolor="black",'
      stream.puts '  color="black"'
      stream.puts ' ];'
      write_dataflow(stream, model.main)
      stream.puts '}'
      
      stream.flush
    end
    
    def write_dataflow(stream, dataflow, prefix="", name="", depth=0) # :nodoc:
      if name != ""
        stream.puts "subgraph cluster_#{prefix}#{name} {"
        stream.puts " label=\"#{name}\""
        stream.puts ' fontname="Helvetica"'
        stream.puts ' fontsize="10"'
        stream.puts ' fontcolor="black"'
        stream.puts ' clusterrank="local"'
        stream.puts " fillcolor=\"#{@@fill_colours[depth % @@fill_colours.length]}\""
        stream.puts ' style="filled"'
      end
      dataflow.processors.each {|processor| write_processor(stream, processor, prefix, depth)}
      write_source_cluster(stream, dataflow.sources, prefix)
      write_sink_cluster(stream, dataflow.sinks, prefix)
      dataflow.datalinks.each {|link| write_link(stream, link, dataflow, prefix)}
      dataflow.coordinations.each {|coordination| write_coordination(stream, coordination, dataflow, prefix)}
      if name != ""
        stream.puts '}'
      end
    end
    
    def write_processor(stream, processor, prefix, depth) # :nodoc:
      # nested workflows
      if "#{processor.type}" == "workflow"
        dataflow = @t2flow_model.dataflow(processor.dataflow_id)
        write_dataflow(stream, dataflow, prefix + processor.name, processor.name, depth.next)
      else
        stream.puts " \"#{prefix}#{processor.name}\" ["
        stream.puts "  fillcolor=\"#{get_colour processor.type}\","
        stream.puts '  shape="box",'
        stream.puts '  style="filled",'
        stream.puts '  height="0",'
        stream.puts '  width="0",'
        stream.puts "  label=\"#{processor.name}\""
        stream.puts ' ];'
      end
    end
    
    def write_source_cluster(stream, sources, prefix) # :nodoc:
      stream.puts " subgraph cluster_#{prefix}sources {"
      stream.puts '  style="dotted"'
      stream.puts '  label="Workflow Inputs"'
      stream.puts '  fontname="Helvetica"'
      stream.puts '  fontsize="10"'
      stream.puts '  fontcolor="black"'
      stream.puts '  rank="same"'
      stream.puts " \"#{prefix}WORKFLOWINTERNALSOURCECONTROL\" ["
      stream.puts '  shape="triangle",'
      stream.puts '  width="0.2",'
      stream.puts '  height="0.2",'
      stream.puts '  fillcolor="brown1"'
      stream.puts '  label=""'
      stream.puts ' ]'
      sources.each {|source| write_source(stream, source, prefix)}
      stream.puts ' }'
    end
    
    def write_source(stream, source, prefix) # :nodoc:
      stream.puts " \"#{prefix}WORKFLOWINTERNALSOURCE_#{source.name}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{source.name}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="skyblue"'
      stream.puts ' ]' 
    end
    
    def write_sink_cluster(stream, sinks, prefix) # :nodoc:
      stream.puts " subgraph cluster_#{prefix}sinks {"
      stream.puts '  style="dotted"'
      stream.puts '  label="Workflow Outputs"'
      stream.puts '  fontname="Helvetica"'
      stream.puts '  fontsize="10"'
      stream.puts '  fontcolor="black"'
      stream.puts '  rank="same"'
      stream.puts " \"#{prefix}WORKFLOWINTERNALSINKCONTROL\" ["
      stream.puts '  shape="invtriangle",'
      stream.puts '  width="0.2",'
      stream.puts '  height="0.2",'
      stream.puts '  fillcolor="chartreuse3"'
      stream.puts '  label=""'
      stream.puts ' ]'
      sinks.each {|sink| write_sink(stream, sink, prefix)}
      stream.puts ' }'
    end
    
    def write_sink(stream, sink, prefix) # :nodoc:
      stream.puts " \"#{prefix}WORKFLOWINTERNALSINK_#{sink.name}\" ["
      stream.puts '   shape="box",'
      stream.puts "   label=\"#{sink.name}\""
      stream.puts '   width="0",'
      stream.puts '   height="0",'
      stream.puts '   fillcolor="lightsteelblue2"'
      stream.puts ' ]'     
    end
    
    def write_link(stream, link, dataflow, prefix) # :nodoc:
      if dataflow.sources.select{|s| s.name == link.source} != []
        stream.write " \"#{prefix}WORKFLOWINTERNALSOURCE_#{link.source}\""
      else 
        processor = dataflow.processors.select{|p| p.name == link.source.split(':')[0]}[0]
        if "#{processor.type}" == "workflow"
          df = @t2flow_model.dataflow(processor.dataflow_id)
          stream.write " \"#{prefix}#{processor.name}WORKFLOWINTERNALSINK_#{link.source.split(':')[1]}\""
        else
          stream.write " \"#{prefix}#{processor.name}\""
        end
      end
      stream.write '->'
      if dataflow.sinks.select{|s| s.name == link.sink} != []
        stream.write "\"#{prefix}WORKFLOWINTERNALSINK_#{link.sink}\""
      else 
        processor = dataflow.processors.select{|p| p.name == link.sink.split(':')[0]}[0]
        if "#{processor.type}" == "workflow"
          df = @t2flow_model.dataflow(processor.dataflow_id)
          stream.write "\"#{prefix}#{processor.name}WORKFLOWINTERNALSOURCE_#{link.sink.split(':')[1]}\""
        else
          stream.write "\"#{prefix}#{processor.name}\""
        end
      end
      stream.puts ' ['
      stream.puts ' ];'
    end
    
    def write_coordination(stream, coordination, dataflow, prefix) # :nodoc:
      stream.write " \"#{prefix}#{coordination.control}" 
      processor = dataflow.processors.select{|p| p.name == coordination.control}[0]
      
      stream.write 'WORKFLOWINTERNALSINKCONTROL' if "#{processor.type}" == "workflow"
      stream.write '"->"'
      stream.write "#{prefix}#{coordination.target}"
      processor = dataflow.processors.select{|p| p.name == coordination.target}[0]
      stream.write 'WORKFLOWINTERNALSOURCECONTROL' if "#{processor.type}" == "workflow"
      stream.write "\""
      stream.puts ' ['
      stream.puts '  color="gray",'
      stream.puts '  arrowhead="odot",'
      stream.puts '  arrowtail="none"'
      stream.puts ' ];'
    end
    
    def get_colour(processor_name) # :nodoc:
      colour = @@processor_colours[processor_name]
      if colour
        colour
      else 
        'white'
      end  
    end
    
    # Returns true if the given name is a processor; false otherwise
    def Dot.is_processor?(processor_name)
      true if @@processor_colours[processor_name]
    end
    
  end
  
end
