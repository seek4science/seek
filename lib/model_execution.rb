# To change this template, choose Tools | Templates
# and open the template in the editor.

module ModelExecution

  #Handles the creation of the applet for running on JWS Online. Requires access to JWS Online, and posts the content
  #of the file and extractes the applet HTML from the response.
  #
  def jws_execution_applet model
    model=model.content_blob.data
  end

end
