def fix_run_output_mime_types(run)
  run.outputs.each do |output|
    port = run.workflow.output_ports.detect {|o| o.name == output.name }
    if port && !port.mime_type.blank?
      output.metadata[:type] = port.mime_type
      output.save
    end
  end
end
