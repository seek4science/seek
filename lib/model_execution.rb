# To change this template, choose Tools | Templates
# and open the template in the editor.

require "uri"
require "net/http"
require 'multipart'

module ModelExecution
  
  #Handles the creation of the applet for running on JWS Online. Requires access to JWS Online, and posts the content
  #of the file and extractes the applet HTML from the response.
  #
  # Curl equivalent may be: curl -F upfile=@/home/sowen/Desktop/Teusink.xml  http://jjj.mib.ac.uk/webMathematica/upload/upload.jsp
  def jws_execution_applet model
    root_url="http://jjj.mib.ac.uk/webMathematica/"
    jsp="upload/upload.jsp"
    
    filepath=store_data_to_tmp model
    
    part=Multipart.new({:upfile=>filepath})
    
    response = part.post(root_url+jsp)
    
    if response.instance_of?(Net::HTTPInternalServerError)       
      puts response.to_s
      raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
    end
    result = response.body
    
    raise Exception.new("There currently appears to be a problem with JWS Online (empty response)") if result.blank?
    raise Exception.new("There currently appears to be a problem with JWS Online (response is shorter than expected)\n#{result}") if result.length < 10
    
    start_block=result.index(%{<div id="applet_box"})
    end_block=result.index("</div>",start_block)+6
    result=result[start_block...end_block]
    
    result = result.gsub(%{src="/webMathematica/},%{src="}+root_url)
    
    return result
  end
  
  def store_data_to_tmp model
    
    rootpath="#{RAILS_ROOT}/tmp/models"
    FileUtils.mkdir_p(rootpath)
    
    filename="model-#{UUIDTools::UUID.random_create.to_s}-#{model.original_filename}"
    filename="#{rootpath}/#{filename}"
    
    model_data=model.content_blob.data
    File.open(filename, "wb+") { |f| f.write(model_data) }
    
    return filename
    
  end
  
end
