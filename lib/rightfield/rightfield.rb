require 'open4'
module RightField

  JAR_PATH = File.dirname(__FILE__) + "/rightfield-bin.jar"

  def invoke_command path
    id="ddd:42"
    "java -jar #{JAR_PATH} -export -format rdf -id #{id} #{path}"
  end

  def generate_rdf datafile
    cmd = invoke_command datafile.content_blob.filepath

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

end