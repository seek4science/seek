# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira

require 'rubygems'
require 'libxml'
require 'cgi'

module T2Flow
  
  class Parser
    # Returns the model for the given t2flow_file.
    # The method accepts objects of classes File, StringIO and String only.
    # ===Usage
    #   foo = ... # stuff to initialize foo here
    #   bar = T2Flow::Parser.new.parse(foo)
    def parse(t2flow)
      case t2flow.class.to_s
        when /^string$/i
          document = LibXML::XML::Parser.string(t2flow, :options => LibXML::XML::Parser::Options::NOBLANKS).parse
        when /^stringio|file$/i
          t2flow.rewind
          document = LibXML::XML::Parser.string(t2flow.read, :options => LibXML::XML::Parser::Options::NOBLANKS).parse
        else 
          raise "Error parsing file."
      end

      root = document.root
      root.namespaces.default_prefix = "t2"

      raise "Doesn't appear to be a workflow!" if root.name != "workflow"
      version = root["version"]
      
      create_model(root, version)
    end
    
    def create_model(element, version) # :nodoc:
      model = Model.new
      
      local_depends = element.find("//localDependencies")
      if local_depends
        local_depends.each do |dependency|
          dependency.each do |dep|
            model.dependencies = [] if model.dependencies.nil?
            model.dependencies << dep.content unless dep.content =~ /^\s*$/
          end
        end
        model.dependencies.uniq! if model.dependencies
      end
    
      element.each_element do |dataflow|
        next if dataflow["id"].nil? || dataflow["id"].chomp.strip.empty?

        dataflow_obj = Dataflow.new
        dataflow_obj.dataflow_id = dataflow["id"]
        dataflow_obj.role = dataflow["role"]
        
        dataflow.each_element do |elt|
          case elt.name
            when "name"
              dataflow_obj.annotations.name = elt.content
            when "inputPorts"
              elt.each_element { |port| add_source(dataflow_obj, port) }
            when "outputPorts"
              elt.each_element { |port| add_sink(dataflow_obj, port) }
            when "processors"
              elt.each_element { |proc| add_processor(dataflow_obj, proc) }
            when "datalinks"
              elt.each_element { |link| add_link(dataflow_obj, link) }
            when "conditions"
              elt.each_element { |coord| add_coordination(dataflow_obj, coord) }
            when "annotations"
              elt.each_element { |ann| add_annotation(dataflow_obj, ann) }
          end # case elt.name
        end # dataflow.each
        
        model.dataflows << dataflow_obj
      end # element.each
      
      temp = model.processors.select { |x| x.type == "workflow" }
      temp.each do |proc|
        df = model.dataflow(proc.dataflow_id)
        df.annotations.name = proc.name
      end
      
      return model   
    end
    
    def add_source(dataflow, port) # :nodoc:
      return if port.nil? || port.content.chomp.strip.empty?

      source = Source.new
      extract_port_metadata(source, port)            
      dataflow.sources << source
    end
    
    def add_sink(dataflow, port) # :nodoc:
      return if port.nil? || port.content.chomp.strip.empty?
      
      sink = Sink.new      
      extract_port_metadata(sink, port)      
      dataflow.sinks << sink
    end
    
    def add_processor(dataflow, element) # :nodoc:
      processor = Processor.new
      
      temp_inputs = []
      temp_outputs = []
      
      element.each_element do |elt|
        case elt.name
          when "name"
            processor.name = elt.content
          when /inputports/i # ports from services
            elt.each_element { |port| port.each_element { |x| temp_inputs << x.content if x.name=="name" }}
          when /outputports/i # ports from services
            elt.each_element { |port| port.each_element { |x| temp_outputs << x.content if x.name=="name" }}
          when "annotations"
            extract_annotations(processor, elt)
          when "activities" # a processor can only have one kind of activity
            activity = elt.find_first('./t2:activity')
            activity.each_element do |node|
              if node.name == "configBean"
                  activity_node = node.child
                  
                  if node["encoding"] == "dataflow"
                    processor.dataflow_id = activity_node["ref"]
                    processor.type = "workflow"
                  else
                    processor.type = (activity_node.name =~ /martquery/i ?
                        "biomart" : activity_node.name.split(".")[-2])
                    
                    activity_node.each_element do |value_node|
                      case value_node.name
                        when "wsdl"
                          processor.wsdl = value_node.content
                        when "operation"
                          processor.wsdl_operation = value_node.content
                        when /endpoint/i
                          processor.endpoint = value_node.content
                        when /servicename/i
                          processor.biomoby_service_name = value_node.content
                        when /authorityname/i
                          processor.biomoby_authority_name = value_node.content
                        when "category"
                          processor.biomoby_category = value_node.content
                        when "script"
                          processor.script = value_node.content
                        when "value"
                          processor.value = value_node.content
                        when "inputs" # ALL ports present in beanshell
                          value_node.each_element do |input|
                            input.each_element do |x|
                              processor.inputs = [] if processor.inputs.nil?
                              processor.inputs << x.content if x.name == "name" 
                            end
                          end
                        when "outputs" # ALL ports present in beanshell
                          value_node.each_element do |output|
                            output.each_element do |x|
                              processor.outputs = [] if processor.outputs.nil?
                              processor.outputs << x.content if x.name == "name" 
                            end
                          end
                      end # case value_node.name
                    end # activity_node.each
                  end # if else node["encoding"] == "dataflow"
              end # if node.name == "configBean"
            end # activity.each
        end # case elt.name
      end # element.each
      
      processor.inputs = temp_inputs if processor.inputs.nil? && !temp_inputs.empty?
      processor.outputs = temp_outputs if processor.outputs.nil? && !temp_outputs.empty?
      dataflow.processors << processor
    end
    
    def add_link(dataflow, link) # :nodoc:
      datalink = Datalink.new
      
      if sink = link.find_first('./t2:sink')
        if processor = sink.find_first('./t2:processor')
          datalink.sink = "#{processor.content}:"
        else
          datalink.sink = ""
        end
        datalink.sink += "#{sink.find_first('./t2:port').content}"
      end

      if source = link.find_first('./t2:source')
        if processor = source.find_first('./t2:processor')
          datalink.source = "#{processor.content}:"
        else
          datalink.source = ""
        end
        datalink.source += "#{source.find_first('./t2:port').content}"
      end

      dataflow.datalinks << datalink
    end
    
    def add_coordination(dataflow, condition) # :nodoc:
      coordination = Coordination.new
      
      coordination.control = condition["control"]
      coordination.target = condition["target"]
      
      dataflow.coordinations << coordination
    end
    
    def add_annotation(dataflow, annotation) # :nodoc:
      node = LibXML::XML::Parser.string("#{annotation}").parse
      content_node = node.find_first("//annotationBean")

      case content_node["class"]
        when /freetextdescription/i
          dataflow.annotations.descriptions << content_node.find_first('./text').content
        when /descriptivetitle/i
          dataflow.annotations.titles << content_node.find_first('./text').content
        when /author/i
          dataflow.annotations.authors << content_node.find_first('./text').content
        when /semanticannotation/i
          dataflow.annotations.semantic_annotation = parse_semantic_annotation(dataflow, content_node)
        end # case
    end
    
    private 
    
    def extract_port_metadata(port, element)
      element.each_element do |elt|
        case elt.name
          when "name"
            port.name = elt.content
          when "annotations"
            extract_annotations(port, elt)
        end # case
      end # port.each
    end

    def extract_annotations(object, element)
      element.each_element do |ann|
        next if ann.nil? || ann.content.chomp.strip.empty?

        node = LibXML::XML::Parser.string("#{ann}").parse
        content_node = node.find_first("//annotationBean")

        case content_node["class"]
          when /freetextdescription/i
            object.descriptions ||= []
            object.descriptions << content_node.find_first('./text').content
          when /examplevalue/i
            object.example_values ||= []
            object.example_values << content_node.find_first('./text').content
          when /semanticannotation/i
            object.semantic_annotation = parse_semantic_annotation(object, content_node)
        end # case
      end # element.each
    end

    def parse_semantic_annotation(object, content_node)
      type = content_node.find_first('./mimeType').content
      content = CGI.unescapeHTML(content_node.find_first('./content').content)
      SemanticAnnotation.new(object, type, content)
    end
    
  end
  
end
