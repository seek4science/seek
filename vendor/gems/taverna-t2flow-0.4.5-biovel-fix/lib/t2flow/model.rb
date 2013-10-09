# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira
#
# This is the module containing the T2Flow model implementation i.e. the
# model structure/definition and all its internals.

module T2Flow # :nodoc:
  
  # The model for a given Taverna 2 workflow.
  class Model
    # The list of all the dataflows that make up the workflow.
    attr_accessor :dataflows
    
    # The list of any dependencies that have been found inside the workflow.
    attr_accessor :dependencies
    
    # Creates an empty model for a Taverna 2 workflow.
    def initialize
      @dataflows = []
      @dependencies = []
    end
    
    # Retrieve the top level dataflow's name
    def name
      main.name
    end
    
    # Retrieve the top level dataflow ie the MAIN (containing) dataflow
    def main
      @dataflows[0]
    end
    
    # Retrieve the dataflow with the given ID
    def dataflow(df_id)
      df = @dataflows.select { |x| x.dataflow_id == df_id }
      return df[0]
    end
    
    # Retrieve ALL the processors containing beanshells within the workflow.
    def beanshells
      self.all_processors.select { |x| x.type == "beanshell" }
    end

    # Retrieve ALL the processors containing rshells within the workflow.
    def rshells
      self.all_processors.select { |x| x.type == "rshell" }
    end

    # Retrieve ALL the processors containing interactions within the workflow.
    def interactions
      self.all_processors.select { |x| x.type == "interaction" }
    end

    # Retrieve ALL the processors containing components within the workflow.
    def components
      self.all_processors.select { |x| x.type == "component" }
    end
    
    # Retrieve ALL processors of that are webservices WITHIN the model.
    def web_services
      self.all_processors.select { |x| x.type =~ /wsdl|soaplab|biomoby/i }
    end
    
    # Retrieve ALL local workers WITHIN the workflow
    def local_workers
      self.all_processors.select { |x| x.type =~ /local/i }
    end
    
    # Retrieve the datalinks from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all datalinks.
    def datalinks
      self.main.datalinks
    end
    
    # Retrieve ALL the datalinks within a nested workflow
    def all_datalinks
      links = []
      @dataflows.each { |dataflow| links << dataflow.datalinks }
      return links.flatten
    end
    
    # Retrieve the annotations specific to the workflow.  This does not return 
    # any annotations from workflows encapsulated within the main workflow.
    def annotations
      self.main.annotations
    end
    
    # Retrieve processors from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all processors.
    def processors
      self.main.processors
    end
    
    # Retrieve ALL the processors found in a nested workflow
    def all_processors
      procs =[]
      @dataflows.each { |dataflow| procs << dataflow.processors }
      return procs.flatten
    end

    # Retrieve coordinations from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all coordinations.
    def coordinations
      self.main.coordinations
    end
    
    # Retrieve ALL the coordinations found in a nested workflow
    def all_coordinations
      coordinations =[]
      @dataflows.each { |dataflow| coordinations << dataflow.coordinations }
      return coordinations.flatten
    end
    
    # Retrieve the sources(inputs) to the workflow
    def sources
      self.main.sources
    end
    
    # Retrieve ALL the sources(inputs) within the workflow
    def all_sources
      sources =[]
      @dataflows.each { |dataflow| sources << dataflow.sources }
      return sources.flatten
    end
    
    # Retrieve the sinks(outputs) to the workflow
    def sinks
      self.main.sinks
    end
    
    # Retrieve ALL the sinks(outputs) within the workflow
    def all_sinks
      sinks =[]
      @dataflows.each { |dataflow| sinks << dataflow.sinks }
      return sinks.flatten
    end
    
    # Retrieve the unique dataflow ID for the top level dataflow.
    def model_id
      self.main.dataflow_id
    end
    
    # For the given dataflow, return the beanshells and/or services which 
    # have direct links to or from the given processor.
    # If no dataflow is specified, the top-level dataflow is used.
    # This does a recursive search in nested workflows.
    # == Usage
    #   my_processor = model.processor[0]
    #   linked_processors = model.get_processors_linked_to(my_processor)
    #   processors_feeding_into_my_processor = linked_processors.sources
    #   processors_feeding_from_my_processor = linked_processors.sinks
    def get_processor_links(processor)
      return nil unless processor
      proc_links = ProcessorLinks.new
      
      # SOURCES
      sources = self.all_datalinks.select { |x| x.sink =~ /#{processor.name}:.+/ }
      proc_links.sources = []

      # SINKS
      sinks = self.all_datalinks.select { |x| x.source =~ /#{processor.name}:.+/ }
      proc_links.sinks = []
      temp_sinks = []
      sinks.each { |x| temp_sinks << x.sink }
      
      # Match links by port into format
      # my_port:name_of_link_im_linked_to:its_port
      sources.each do |connection|
        link = connection.sink
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]
        
        if my_connection_port
          source = my_connection_port << ":" << connection.source
          proc_links.sources << source if source.split(":").size == 3
        end
      end
      
      sinks.each do |connection|
        link = connection.source
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]
        
        if my_connection_port
          sink = my_connection_port << ":" << connection.sink
          proc_links.sinks << sink if sink.split(":").size == 3
        end
      end
      
      return proc_links
    end
  end
  
  
  
  # The entities within the Taverna 2 mdoel which contains the different 
  # elements of the workflows; processors, sinks, sources, etc...
  class Dataflow
    # This returns a DataflowAnnotation object.
    attr_accessor :annotations
    
    # Retrieve the list of processors specific to the dataflow.
    attr_accessor :processors
    
    # Retrieve the list of datalinks specific to the dataflow.
    attr_accessor :datalinks
    
    # Retrieve the list of sources specific to the dataflow.
    attr_accessor :sources
    
    # Retrieve the list of sinks specific to the dataflow.
    attr_accessor :sinks
    
    # Retrieve the list of coordinations specific to the dataflow.
    attr_accessor :coordinations
    
    # The unique identifier of the dataflow.
    attr_accessor :dataflow_id
    
    # The role of the workflow
    attr_accessor :role

    # Creates a new Dataflow object.
    def initialize
      @annotations = DataflowAnnotation.new
      @processors = []
      @datalinks = []
      @sources = []
      @sinks = []
      @coordinations = []
    end
    
    def name
      @annotations.name
    end
    
    # Retrieve beanshell processors specific to this dataflow.
    def beanshells
      @processors.select { |x| x.type == "beanshell" }
    end

    # Retrieve rshell processors specific to this workflow.
    def rshells
      @processors.select { |x| x.type == "rshell" }
    end
    
    # Retrieve interaction processors specific to this workflow.
    def interactions
      @processors.select { |x| x.type == "interaction" }
    end

    # Retrieve component processors specific to this workflow.
    def components
      @processors.select { |x| x.type == "component" }
    end

  end


  
  # This is the (shim) object within the workflow.  This can be a beanshell,
  # a webservice, a workflow, etc...
  class Processor
    # A string containing name of the processor.
    attr_accessor :name 
    
    # A string containing the description of the processor if available.  
    # Returns nil otherwise.
    attr_accessor :descriptions

    def description
      @descriptions.first
    end
    
    # A string for the type of processor, e.g. beanshell, workflow, webservice, etc...
    attr_accessor :type 
    
    # For processors that have type "dataflow", this is the the reference 
    # to the dataflow.  For all other processor types, this is nil.
    attr_accessor :dataflow_id
    
    # This only has a value in beanshell processors.  This is the actual script
    # embedded with the processor which does all the "work"
    attr_accessor :script
    
    # This is a list of inputs that the processor can take in.
    attr_accessor :inputs
    
    # This is a list of outputs that the processor can produce.
    attr_accessor :outputs
    
    # For processors of type "arbitrarywsdl", this is the URI to the location
    # of the wsdl file.
    attr_accessor :wsdl
    
    # For processors of type "arbitrarywsdl", this is the operation invoked.
    attr_accessor :wsdl_operation
    
    # For soaplab and biomoby services, this is the endpoint URI.
    attr_accessor :endpoint
    
    # Authority name for the biomoby service.
    attr_accessor :biomoby_authority_name

    # Service name for the biomoby service. This is not necessarily the same 
    # as the processors name.
    attr_accessor :biomoby_service_name
    
    # Category for the biomoby service.
    attr_accessor :biomoby_category

    # Value for string constants
    attr_accessor :value

    attr_accessor :semantic_annotation

    def initialize
      @descriptions = []
    end

  end


  # This object is returned after invoking model.get_processor_links(processor)
  # .  The object contains two lists of processors.  Each element consists of: 
  # the input or output port the processor uses as a link, the name of the
  # processor being linked, and the port of the processor used for the linking,
  # all seperated by a colon (:) i.e. 
  #   my_port:name_of_processor:processor_port
  class ProcessorLinks
    # The processors whose output is fed as input into the processor used in
    # model.get_processors_linked_to(processor).
    attr_accessor :sources
    
    # A list of processors that are fed the output from the processor (used in
    # model.get_processors_linked_to(processor) ) as input.
    attr_accessor :sinks
  end
  
  
  
  # This is the annotation object specific to the dataflow it belongs to.
  # A DataflowAnnotation contains metadata about a given dataflow element.
  class DataflowAnnotation
    # The name used of the dataflow
    attr_accessor :name
    
    # A list of titles that have been assigned to the dataflow.
    attr_accessor :titles
    
    # A list ot descriptive strings about the dataflow.
    attr_accessor :descriptions
    
    # A list of authors of the dataflow
    attr_accessor :authors

    attr_accessor :semantic_annotation
    
    def initialize
      @authors, @descriptions, @titles  = [], [], []
    end
  end
  
  
  
  # This represents a connection between any of the following pair of entities:
  # {processor -> processor}, {workflow -> workflow}, {workflow -> processor}, 
  # and {processor -> workflow}.
  class Datalink
    # The name of the source (the starting point of the connection).
    attr_accessor :source
    
    # The name of the sink (the endpoint of the connection).
    attr_accessor :sink
  end
  
  
  
  # This is a representation of the 'Run after...' function in Taverna
  # where the selected processor or workflow is set to run after another.
  class Coordination
    # The name of the processor/workflow which is to run first.
    attr_accessor :control
    
    # The name of the processor/workflow which is to run after the control.
    attr_accessor :target
  end
  
  
  
  # This is the start node of a Datalink.  Each source has a name and a port
  # which is seperated by a colon; ":".
  # This is represented as "source of a processor:port_name".
  # A string that does not contain a colon can often be returned, signifiying
  # a workflow source as opposed to that of a processor.
  class Source
  	attr_accessor :name, :descriptions, :example_values, :semantic_annotation
  end
  
  
  
  # This is the start node of a Datalink.  Each sink has a name and a port
  # which is seperated by a colon; ":".
  # This is represented as "sink of a processor:port_name".
  # A string that does not contain a colon can often be returned, signifiying
  # a workflow sink as opposed to that of a processor.
  class Sink
	  attr_accessor :name, :descriptions, :example_values, :semantic_annotation
  end


  # A representation of a semantic annotation. It is linked to a +subject+,
  # which can be a processor, port, or dataflow object. It has a +type+, which
  # indicates the MIME type of it's +content+. By default, this will be text/rdf+n3.
  # +Content+ is the content of the annotation, which in n3 form consists of one or more
  # triples.
  class SemanticAnnotation
    attr_reader :subject, :type, :content

    def initialize(subject, type, content)
      @subject = subject
      @type = type
      @content = content
    end

    def to_s
      @content
    end
  end

end
