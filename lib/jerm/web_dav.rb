require 'rubygems'
require 'uri'
require 'net/http'
require 'net/https'
require 'uri'
require 'libxml'
require 'openssl'

module WebDav    

  LibXML::XML.default_warnings=false

  #Returns an array of hashes containing details about each item contained within the directory
  #indicated by the URI provided
  #The contents of each hash contains the followind keys
  #
  # - :is_directory - is true if the item is a directory
  # - :containing_path - the parent path for the item
  # - :full_path - the full uri to the item
  # - :path - the path to the item relative to the root, without the host details.
  # - :updated_at - a DateTime instance for the time the item was last updated
  # - :created_at - a DateTime instance for the time the item was first created
  #
  # in addition, if the recursive parameter is true then each item will contain
  # - :children - an array of items held with the current directory (if the current item is a directory)
  #
  # children are collected for all inner directories until no more directories are found.
  def get_contents uri,user,password,recursive=false
   
    found=[]

    content = propfind uri,user,password,1

    parser = LibXML::XML::Parser.string(content,:encoding => LibXML::XML::Encoding::UTF_8)

    document = parser.parse

    href_nodes = document.find("ns:response","ns:DAV:")
      
    href_nodes.each do |node|
      unless node == href_nodes.first      
        href_node=node.find_first("ns:href","ns:DAV:")
        last_modified_node = node.find_first("*/ns:prop","ns:DAV:").find_first("ns:getlastmodified","ns:DAV:")
        creation_date_node = node.find_first("*/ns:prop","ns:DAV:").find_first("ns:creationdate","ns:DAV:")
        content_type_node = node.find_first("*/ns:prop","ns:DAV:").find_first("ns:getcontenttype","ns:DAV:")

        attributes={          
          :containing_path=>uri.to_s,
          :full_path=>uri.merge(href_node.inner_xml).to_s,
          :updated_at=>DateTime.parse(last_modified_node.inner_xml).to_s,
          :created_at=>DateTime.parse(creation_date_node.inner_xml).to_s,
          :is_directory=>is_dir?(href_node,content_type_node)
        }
        found << attributes
      end
    end
    
    found.select{|a| a[:is_directory]}.each do |dir_tuple|
        child_uri=URI.parse(dir_tuple[:full_path])
        children=get_contents child_uri,user,password,true
        dir_tuple[:children]=children
    end if recursive
    
    return found
    
  end

  private

  def is_dir? href_node,content_type_node
    return content_type_node.inner_xml.include?("directory") unless content_type_node.nil?
    return href_node.inner_xml[-1,1]=="/"
  end

  def propfind uri,user,password,depth=1

    http=Net::HTTP.new(uri.host,uri.port)

    http.use_ssl=true if uri.scheme=="https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Propfind.new(uri.path)
    req.basic_auth user,password
    req.add_field "Depth", depth
    response = http.request(req)

    return response.body

  end

end
