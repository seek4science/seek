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
    root_url="http://jjj.biochem.sun.ac.za/webMathematica/"
    jsp="upload/upload.jsp"
    
    filepath=store_data_to_tmp model
    
    part=Multipart.new({:upfile=>filepath})

    response = part.post(root_url+jsp)
    
    if response.instance_of?(Net::HTTPInternalServerError)      
      raise Exception.new(response.body.gsub(/<head\>.*<\/head>/,""))
    end
    result = response.body
    
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

def applet
  return %{
  
    <!--Needs["buildpack`", "C:\\JWSBase\\Mathematica\\packages\\JWS\\buildpack.m"];-->
    <!--Needs["buildpack`", "/opt/local/JWSBase/Mathematica/packages/JWS/buildpack.m"];-->
  

  
  

      

      <html>
  <head>
    <title>Model model-4-1275054332-potato
 results</title>
    <link rel="stylesheet" type="text/css" href="/styles/jws.css"></link>
    <script type="text/javascript" src="/scripts/jws.js"></script>
  </head>
  <body>
    <div id="container">
      <div id="pagetitle">File model-4-1275054332-potato
 Model assmus
</div>

      <div id="logo"><img src="/images/webpic.jpg" width="800" height="189" alt="JWS banner image"></img ></div>

      <div id="navbar">
  <ul id="links">
    <li><a href="/index.html" title="JWS Online home">Home</li>
    <li><a href="/database/index.html" title="Model database">Model Database</a></li>
    <li><a href="/info.html" title="Project Info">Project Info</a></li>
    <li><a href="/news.html" title="News">News</a></li>
    <li><a href="/upload.html" title="Upload">Upload</a></li>
    <li><a href="/help.html" title="Help">Help</a></li>
    <li>
  <div id="servers">
    <select name="select2" onchange="MM_jumpMenu('parent',this,0)">
      <option selected="selected">Online servers</option>
      <option value="http://jjj.biochem.sun.ac.za/index.html">Stellenbosch (za)</option>
      <option value="http://jjj.bio.vu.nl/index.html">Amsterdam (nl)</option>
      <option value="http://jjj.mib.ac.uk:8080/index.html">Manchester (uk)</option>
    </select>
  </div>
      </li>
      </ul>
      </div>

      <div id="content_frame">
        <div id="content">
    <div id="applet_box">
<!--      <IFRAME src="http://jjj.biochem.sun.ac.za/webMathematica/Examples/jjjLoad.jsp?fun=%22JWS%60assmus%60%22" frameborder="0" bgcolor="#CCCCCC"  align="left"  scrolling="no"></IFRAME> -->
      <IFRAME src="http://jjj.biochem.sun.ac.za/webMathematica/upload/jjjLoadUpload.jsp?fun=%22assmus20100528064524%60%22&mfile=%22/Users/jls/Siteshttp://jjj.biochem.sun.ac.za/webMathematica/upload/tmp/JWS/assmus20100528064524.m%22" frameborder="0" bgcolor="#CCCCCC"  align="left"  scrolling="no"></IFRAME> 
    </div>

    <div id="save_form">
      <p class="upload_info_item">
        Use the following if you wish to save the model on the
        JWS Online system for re-use.
      </p>
      <p class="upload_info_item">
        N.B. Although we do not disclose the names of the stored
        models to anybody, we do not guarantee that other users
        will not be able to view saved models. Please do not
        save models on the system if you absolutely do not wish
        others to see them.
      </p>
      <form method="POST" action="http://jjj.biochem.sun.ac.za/webMathematica/upload/saveData.jsp">
      <div class="form_item">
        <div class="textline">
    Save SBML:
        </div>
        <div class="box">
    <input type="checkbox" name="save_sbml" value="model-4-1275054332-potato"></input>
        </div>
      </div>
      <div class="form_item">
        <div class="textline">
    Save JWS input: 
        </div>
        <div class="box">
    <input type="checkbox" name="save_dat" value="model-4-1275054332-potato">
        </div>
      </div>
      <div class="form_item">
        <div id="submit_but">
    <input type="submit" name="save" value="Submit">
        </div>
      </div>
            </form>
    </div>

  </div>
      </div>
    </div>

  </body>
  </head>

    }
end

end
