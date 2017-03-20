module SweepsHelper
  # Return an array of table rows, one for each workflow output port
  def sweep_results_table_upside_down(sweep)
    workflow = sweep.executed_workflow
    output_ports = workflow.output_ports

    output_ports.map do |output_port|
      # Checkbox to select the whole row
      row = [check_box_tag(output_port.name, output_port.name, false, class: 'chk-select-row')] # second parameter is used to populate the element's value attribute and gets passed in params

      # Name of the output port
      row << output_port.name

      # Values of this output port for each run
      sweep.runs.each_with_index do |run, i|
        chk_box = check_box_tag("download[#{output_port.name}][]", run.id, false, multiple: true, class: 'chk-select', id: "download_run#{i + 1}_#{output_port.name}")
        link_to_view = link_to 'View', view_result_sweep_path(run_id: run.id, output_port_name: output_port.name), remote: true
        row << "#{chk_box} &nbsp;&nbsp;#{link_to_view}".html_safe
      end
      row
    end
  end

  # Return an array of table rows, one for each run in the sweep
  def sweep_results_table(sweep)
    workflow = sweep.executed_workflow
    output_ports = workflow.output_ports

    rows = []

    # Values of all the output ports for each run
    sweep.runs.select(&:can_view?).each_with_index do |run, i|
      # Run name
      row = [link_to("#{image('simple_run')}#{run.name}".html_safe, taverna_player.run_path(run), class: 'with_icon')]

      output_ports.each do |output_port|
        # If output value is not available for some reason, e.g. the run failed, disable the checkbox and do not show the link
        output = run.outputs.select { |out| out.name == output_port.name }[0] # Get the actual output from the run for this output port
        if output.blank?
          chk_box = ''
          link_to_view = 'N/A'
        else
          chk_box = check_box_tag("download[#{run.id}][]", output_port.name, false, multiple: true, class: 'chk-select', id: "download_run#{i + 1}_#{output_port.name}")
          link_to_view = link_to '(View)', view_result_sweep_path(run_id: run.id, output_port_name: output_port.name), remote: true, class: 'preview_result'
        end

        row << "#{chk_box}<br/>#{link_to_view}".html_safe
      end

      rows << row
    end

    rows
  end

  # Returns a hash of input data, indexed by the inputs name
  def input_json_hash(inputs)
    input_hash = {}
    inputs.each_with_index do |i, index|
      input_hash[i.name] = { input_number: index,
                             name: i.name,
                             description: i.description,
                             example_value: i.example_value }
    end
    input_hash.to_json.html_safe
  end
end
