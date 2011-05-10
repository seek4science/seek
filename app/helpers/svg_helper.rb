module SvgHelper

  def serve_svg_locally data_url
    svg_content = open(data_url).read
    uuid=UUIDTools::UUID.random_create.to_s
    dir="#{RAILS_ROOT}/tmp/models"
    FileUtils.mkdir_p dir 
    f=open("#{dir}/#{uuid}.svg","w")
    f.write svg_content
    f.flush
    svg_path(:id=>uuid,:format=>"svg")
  end


end
