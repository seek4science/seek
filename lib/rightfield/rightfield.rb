require 'open4'
require 'rdf/rdfxml'

module RightField
  JAR_PATH = File.dirname(__FILE__) + '/rightfield-bin.jar'

  def invoke_rdf_command(datafile)
    id = rdf_resource_uri(datafile)
    "java -jar #{JAR_PATH} -export -format rdf -id #{id} #{datafile.content_blob.filepath}"
  end

  def invoke_csv_command(datafile)
    "java -jar #{JAR_PATH} -export -format csv #{datafile.content_blob.filepath}"
  end

  def rdf_resource_uri(datafile)
    URI.join(Seek::Config.site_base_host, "/data_files/#{datafile.id}").to_s
  end

  def generate_rightfield_csv(datafile)
    Rails.cache.fetch("#{datafile.content_blob.filepath}_rf_csv") do
      cmd = invoke_csv_command datafile

      output = ''

      status = Open4.popen4(cmd) do |_pid, _stdin, stdout, stderr|
        while (line = stdout.gets) != nil
          output << line
        end
        stdout.close

        stderr.close
      end

      if status.to_i != 0
        # error message is coming out through stdout rather than stderr due to log4j configuration.
        raise Exception, output
      end

      output.strip
    end
  end

  def generate_rightfield_rdf(datafile)
    Rails.cache.fetch("#{datafile.content_blob.filepath}_rf_rdf") do
      cmd = invoke_rdf_command datafile

      output = ''

      status = Open4.popen4(cmd) do |_pid, _stdin, stdout, stderr|
        while (line = stdout.gets) != nil
          output << line
        end
        stdout.close

        stderr.close
      end

      if status.to_i != 0
        # error message is coming out through stdout rather than stderr due to log4j configuration.
        raise Exception, output
      end

      output.strip
    end
  end

  def generate_rightfield_rdf_graph(datafile)
    rdf = generate_rightfield_rdf datafile
    graph = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      reader.each_statement do |stmt|
        graph << stmt
      end
    end
    graph
  end
end
