require 'open4'
require 'rdf/rdfxml'

module RightField

  JAR_PATH = File.dirname(__FILE__) + "/rightfield-bin.jar"

  def invoke_command datafile
    id=rdf_resource_uri(datafile)
    "java -Djava.awt.headless=true -jar #{JAR_PATH} -export -format rdf -id #{id} #{datafile.content_blob.filepath}"
  end

  def rdf_resource_uri datafile
    Seek::Config.site_base_host+"/data_files/#{datafile.id}"
  end

  def generate_rdf datafile
    cmd = invoke_command datafile

    output = ""
      err_message = ""

      status = Open4::popen4(cmd) do |pid, stdin, stdout, stderr|
        while ((line = stdout.gets) != nil) do
          output << line
        end
        stdout.close

        while ((line=stderr.gets)!= nil) do
          err_message << line
        end
        stderr.close
      end

      if status.to_i != 0
        raise Exception.new(err_message)
      end

      output.strip
  end

  def generate_rdf_graph datafile
    rdf = generate_rdf datafile
    f=Tempfile.new("rdf")
    f.write(rdf)
    f.flush
    RDF::Graph.load(f.path)

  end

end