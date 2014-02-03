def fix_types_and_extensions(run)
  fix_run_output_ports_mime_types(run)
  fix_file_extensions(run)
end

def fix_run_output_ports_mime_types(run)
  run.outputs.each do |output|
    output.metadata = {:size => nil, :type => ''} if output.metadata.nil?
    port = run.executed_workflow.output_ports.detect { |o| o.name == output.name }
    if port && !port.mime_type.blank?
      if output.depth > 0
        output.metadata[:type] = recursively_set_mime_type(output.metadata[:type], output.depth, port.mime_type)
      elsif output.metadata[:type] != "application/x-error"
        output.metadata[:type] = port.mime_type
      end
      output.save
    end
  end
end

# Add file extensions to all files in the results zip
def fix_file_extensions(run)
  Zip::ZipFile.open(run.results.path) do |zip|
    zip.each do |file|
      output = run.outputs.detect { |o| o.name == file.name.split('/').first }
      unless file.name.ends_with?('.error')
        ext = output.file_extension
        zip.rename(file.name, "#{file.name}#{ext}") unless ext.nil?
      end
    end
  end

  run.outputs.select { |o| o.depth > 0 }.each do |output|
    ext = output.file_extension
    Zip::ZipFile.open(output.file.path) do |zip|
      zip.each do |file|
        unless file.name.ends_with?('.error')
          zip.rename(file.name, "#{file.name}#{ext}") unless ext.nil?
        end
      end
    end
  end
end

private

def recursively_set_mime_type(list, depth, type)
  depth -= 1
  list.map do |el|
    if depth == 0
      el == "application/x-error" ? el : type
    else
      recursively_set_mime_type(el, depth, type)
    end
  end
end
