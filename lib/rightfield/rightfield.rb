require 'open4'
require 'rdf/rdfxml'

module RightField

  JAR_PATH = File.dirname(__FILE__) + "/rightfield-bin.jar"

  def invoke_command datafile
    id=rdf_resource_uri(datafile)
    "java -jar #{JAR_PATH} -export -format rdf -id #{id} #{datafile.content_blobs.first.filepath}"
  end

  def rdf_resource_uri datafile
    URI.join(Seek::Config.site_base_host, "/data_files/#{datafile.id}").to_s
  end

  def generate_rightfield_rdf datafile
    cmd = invoke_command datafile

    output = ""

    status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
      while ((line = stdout.gets) != nil) do
        output << line
      end
      stdout.close

      stderr.close
    end

    if status.to_i != 0
      #error message is coming out through stdout rather than stderr due to log4j configuration.
      raise Exception.new(output)
    end

    output.strip
  end

  def generate_rightfield_rdf_graph datafile
    rdf = generate_rightfield_rdf datafile
    f=Tempfile.new("rdf")
    f.write(rdf)
    f.flush
    graph = RDF::Graph.new
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      reader.each_statement do |stmt|
        graph << stmt
      end
    end
    graph

  end

end