# To change this template, choose Tools | Templates
# and open the template in the editor.

require "uri"
require "net/http"
require 'Multipart'

module ModelExecution

  #Handles the creation of the applet for running on JWS Online. Requires access to JWS Online, and posts the content
  #of the file and extractes the applet HTML from the response.
  #
  def jws_execution_applet model
    url="http://jjj.biochem.sun.ac.za/webMathematica/upload/upload_stuart.jsp"

    part=Multipart.new({:upfile=>"c:/Users/sowen/Desktop/Teusink.xml"})

    return part.post(url)
  end

end
