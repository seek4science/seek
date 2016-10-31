require 'ftools'
is_root = false unless local_assigns.has_key?(:is_root)
data_file=open(@cache_file)

parent_xml.tag! "avatar",
core_xlink(avatar).merge(is_root ? xml_root_attributes : {}) do
  
  render :partial=>"api/standard_elements",:locals=>{:parent_xml => parent_xml,:is_root=>is_root,:object=>avatar}
  if (is_root)
    parent_xml.tag! "owner" do
      api_partial(parent_xml,avatar.owner)
    end
    parent_xml.tag! "content_length", File.size(@cache_file)
    parent_xml.tag! "dimensions",params[:size]
    parent_xml.tag! "data",ActiveSupport::Base64.encode64(open(@cache_file) { |io| io.read }),{:type=>@type}
  end
end