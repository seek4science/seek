# To change this template, choose Tools | Templates
# and open the template in the editor.

require "uri"
require "net/http"
require 'multipart'

module ModelExecution

  #Handles the creation of the applet for running on JWS Online. Requires access to JWS Online, and posts the content
  #of the file and extractes the applet HTML from the response.
  #
  # Curl equivalent may be: curl -F upfile=@/home/sowen/Desktop/Teusink.xml  http://jjj.biochem.sun.ac.za/webMathematica/upload/upload_stuart.jsp
  def jws_execution_applet model
    url="http://jjj.biochem.sun.ac.za/webMathematica/upload/upload_stuart.jsp"

    filepath=store_data_to_tmp model

    part=Multipart.new({:upfile=>filepath})

    return part.post(url)
  end

  def store_data_to_tmp model
        
    rootpath="#{RAILS_ROOT}/tmp/models"
    FileUtils.mkdir_p(rootpath)
    
    filename="model-#{model.id}-#{Time.now.to_i}-#{model.original_filename}"
    filename="#{rootpath}/#{filename}"

    model_data=model.content_blob.data
    File.open(filename, "wb+") { |f| f.write(model_data) }
    
    return filename

  end

end
