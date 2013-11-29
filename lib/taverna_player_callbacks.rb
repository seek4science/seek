def fix_run_output_ports_mime_types(run)
  run.outputs.each do |output|
    output.metadata = {:size => nil, :type => ''} if output.metadata.nil?
    port = run.workflow.output_ports.detect { |o| o.name == output.name }
    if port && !port.mime_type.blank?
      if output.depth > 0
        output.metadata[:type] = recursively_set_mime_type(output.metadata[:type], output.depth, port.mime_type)
      else
        output.metadata[:type] = port.mime_type
      end
      output.save
    end
  end
end

private

def recursively_set_mime_type(list, depth, type)
  depth -= 1
  list.map do |el|
    if depth == 0
      type
    else
      recursively_set_mime_type(el, depth, type)
    end
  end
end

