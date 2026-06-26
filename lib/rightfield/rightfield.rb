require 'open4'
require 'rdf/rdfxml'

module Rightfield
  module Rightfield
    JAR_PATH = File.dirname(__FILE__) + '/rightfield-bin.jar'

    def invoke_rdf_command(datafile, path)
      id = rdf_resource_uri(datafile)
      "java -jar #{JAR_PATH} -export -format rdf -id #{id} #{path}"
    end

    def invoke_csv_command(_datafile, path)
      "java -jar #{JAR_PATH} -export -format csv #{path}"
    end

    def rdf_resource_uri(datafile)
      Seek::Util.routes.data_file_url(datafile)
    end

    def generate_rightfield_csv(datafile)
      # Cache key is path-independent (cache_key), so it is stable across backends.
      Rails.cache.fetch("rf_csv-#{datafile.content_blob.cache_key}") do
        # The RightField JAR needs a real local file; stream a temp copy so this works on S3 too.
        datafile.content_blob.with_temporary_copy do |path|
          run_rightfield_command(invoke_csv_command(datafile, path))
        end
      end
    end

    def generate_rightfield_rdf(datafile)
      Rails.cache.fetch("rf_rdf-#{datafile.content_blob.cache_key}") do
        datafile.content_blob.with_temporary_copy do |path|
          run_rightfield_command(invoke_rdf_command(datafile, path))
        end
      end
    end

    # Runs a RightField JAR command via Open4 and returns its stripped stdout, raising on a non-zero
    # exit. Shared by the CSV and RDF generators.
    def run_rightfield_command(cmd)
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
end
