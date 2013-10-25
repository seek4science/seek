module SweepsHelper

  # Return an array of table rows, one for each workflow output port
  def sweep_results_table(sweep)
    workflow = sweep.workflow
    output_ports = workflow.output_ports

    output_ports.map do |output_port|

      # Checkbox to select the whole row
      row = [check_box_tag(output_port.name, output_port.name, false, {:class => 'chk-select-row'})]  # second parameter is used to populate the element's value attribute and gets passed in params

      # Name of the output port
      row << output_port.name

      # Values of this output port for each run
      sweep.runs.each_with_index do |run, i|
        chk_box = check_box_tag("download[#{output_port.name}][]", run.id, false, {:multiple => true, :class => 'chk-select', :id => "download_run#{i+1}_#{output_port.name}"})
        link_to_view = link_to('View', view_result_sweep_path(:run_id => run.id, :output_port_name => output_port.name))
        row << "#{chk_box} &nbsp;&nbsp;#{link_to_view}".html_safe
      end
      row
    end
  end

end

