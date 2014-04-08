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

# Add file extensions to all the entries in all the results zips. We have to
# Copy things into a new file due to problems with the Mac Archive Utility.
def fix_file_extensions(run)
  Dir.mktmpdir("#{run.id}", Rails.root.join("tmp")) do |tmp_dir|
    tmp_zip = File.join(tmp_dir, "all.zip")
    Zip::ZipFile.open(run.results.path) do |old_zip|
      Zip::ZipFile.open(tmp_zip, Zip::ZipFile::CREATE) do |new_zip|
        old_zip.each do |file|
          output = run.outputs.detect { |o| o.name == file.name.split('/').first }
          ext = output.nil? ? nil : output.file_extension

          copy_file_between_zips(old_zip, new_zip, file.name, ext)
        end
      end
    end

    run.results = File.new(tmp_zip)
    run.save

    run.outputs.select { |o| o.depth > 0 }.each do |output|
      ext = output.file_extension
      tmp_zip = File.join(tmp_dir, File.basename(output.file.path))
      Zip::ZipFile.open(output.file.path) do |old_zip|
        Zip::ZipFile.open(tmp_zip, Zip::ZipFile::CREATE) do |new_zip|
          old_zip.each do |file|
            copy_file_between_zips(old_zip, new_zip, file.name, ext)
          end
        end
      end

      output.file = File.new(tmp_zip)
      output.save
    end

  end
end

private

# This streams data between two zip files (both previously opened) and adds a
# file extension where appropriate.
def copy_file_between_zips(src, dest, name, ext)
  if name.ends_with?('.error')
    new_name = name
  else
    new_name = ext.nil? ? name : "#{name}#{ext}"
  end

  dest.get_output_stream(new_name) do |zos|
    src.get_input_stream(name) do |zis|
      while !(buffer = zis.read(32768)).nil?
        zos.write buffer
      end
    end
  end
end

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
