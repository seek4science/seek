# Taverna Player configuration

TavernaPlayer.setup do |config|
  # This should be set to the name of the workflow model class in the main
  # application and the listed methods should also be mapped if necessary.
  # config.workflow_model_proxy("Workflow")
  config.workflow_model_proxy("Workflow") do |proxy|
    # This is the method that returns the name of the workflow file. Your
    # model MUST provide this otherwise a workflow cannot be run.
    proxy.file_method_name = :file_path

    # This is the method that returns the title of the workflow. This can be
    # left unset if your model does not have this field but if you want to
    # set a run name at the time of run creation then you will need to
    # provide one or override the new run view.
    proxy.title_method_name = :title

    # This is a method that returns a list of descriptions of the workflow
    # inputs. Each description should be of the form:
    #  {
    #    :name => "<input_name>",
    #    :description => "<input_description>",
    #    :example => "<input_example_value>"
    #  }
    #
    # If you don't provide this method you will have to override the new run
    # view to create and initialize the inputs to a workflow.
    proxy.inputs_method_name = :input_ports
  end

  # Callbacks to be run at various points during a workflow run. These can be
  # defined as Proc objects or as methods and referenced by name.
  #
  # Be careful! If a callback fails then the worker running the job will fail!
  #
  # Add callbacks in this initializer or define them elsewhere and require the
  # file as usual (if they are not pulled in by some other code). You can
  # create example stub callbacks using:
  #   "rails generate taverna_player:callbacks"
  # which will put them in "lib/taverna_player_callbacks.rb".
  #require "taverna_player_callbacks"

  # The pre-run callback is called before the run has started (before Taverna
  # Server is contacted, in fact).
  # It takes the run model object as its parameter.
  #config.pre_run_callback = Proc.new { |run| puts "Starting: #{run.name}" }
  #config.pre_run_callback = "player_pre_run_callback"
  #config.pre_run_callback = :player_pre_run_callback

  # The post-run callback is called after the run has completed normally.
  # It takes the run model object as its parameter.
  #config.post_run_callback = Proc.new { |run| puts "Finished: #{run.name}" }
  #config.post_run_callback = "player_post_run_callback"
  config.post_run_callback = :fix_types_and_extensions

  # The run-cancelled callback is called if the run is cancelled by the user.
  # It takes the run model object as its parameter.
  #config.run_cancelled_callback = Proc.new { |run| puts "Cancelled: #{run.name}" }
  #config.run_cancelled_callback = "player_run_cancelled_callback"
  #config.run_cancelled_callback = :player_run_cancelled_callback

  # Callbacks to be run to render various types of workflow output. These can
  # be defined as Proc objects or as methods and referenced by name.
  #
  # Be careful! If a callback fails then users will see an Internal Server
  # Error (HTTP status code 500) instead of their run outputs!
  #
  # Add callbacks in this initializer or define them elsewhere and require the
  # file as usual (if they are not pulled in by some other code). You can
  # create example stub callbacks using:
  #   "rails generate taverna_player:renderers"
  # which will put them in "lib/taverna_player_renderers.rb".
  #require "taverna_player_renderers"

  # Renderers for each type of output (referenced by MIME type) must then be
  # registered. All the renderers shown below are supplied as defaults.
  config.port_renderers do |renderers|
    # Set a default renderer for if there is a workflow type that browsers
    # can't otherwise handle.
    #renderers.default(:cannot_inline)

    # You can set a renderer to also be a default for the whole media-type. In
    # this case the below renderer is to be used for ALL text/* types that
    # aren't otherwise registered.
    #renderers.add("text/plain", :format_text, true)

    # This renderer overrides the default text/* renderer for text/xml outputs.
    #renderers.add("text/xml", :format_xml)

    # Browsers can't show all image types so just register very common ones.
    #renderers.add("image/jpeg", :show_image)
    #renderers.add("image/png", :show_image)
    #renderers.add("image/gif", :show_image)
    #renderers.add("image/bmp", :show_image)
    renderers.add("application/json", :format_json)
    renderers.add("application/xml", :format_xml)
    renderers.add("text/xml", :format_xml)
    renderers.add("text/csv", :format_csv)

    # This is the workflow error type and you should have a special renderer
    # for it.
    #renderers.add("application/x-error", :workflow_error)
  end
end

# Example workflow run callbacks defined in the initializer.

#def player_pre_run_callback(run)
#  puts "Starting: #{run.name}"
#end

#def player_post_run_callback(run)
#  puts "Finished: #{run.name}"
#end

#def player_run_cancelled_callback(run)
#  puts "Cancelled: #{run.name}"
#end
