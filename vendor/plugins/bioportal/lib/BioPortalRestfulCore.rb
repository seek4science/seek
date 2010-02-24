require "rubygems"

require "date"
require "net/http"
require 'xml'
require "rexml/document"
require 'open-uri'
require 'uri'
require 'cgi'
require 'BioPortalResources'
require 'ontology_wrapper'
require 'node_wrapper'

class BioPortalRestfulCore
  
  # Resources
  BASE_URL = $REST_URL
  
  # Search URL
  SEARCH_PATH = "/search/%query%?%ONT%"
  
  # Constants
  SUPERCLASS = "SuperClass"
  SUBCLASS = "SubClass"
  CHILDCOUNT = "ChildCount"
  APPLICATION_ID = "4ea81d74-8960-4525-810b-fa1baab576ff"
  
  # Track paths that have already been processed when building a path to root tree 
  @seen_paths = {}
  
  def self.getView(params)
    uri_gen = BioPortalResources::View.new(params)
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(open(uri))
    
    view = nil
    doc.elements.each("*/data/ontologyBean"){ |element|  
      view = parseOntology(element)
    }  

    return view
  end
  
  def self.getViews(params)
    uri_gen = BioPortalResources::ViewVersions.new(params)
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(open(uri))

    views = []
    doc.elements.each("*/data/list/list"){ |element|
      virtual_view = []
      element.elements.each{ |version|      
        virtual_view << parseOntology(version)
      }
        views << virtual_view
    }  

    return views
  end      
  
  def self.getCategories()
    uri_gen = BioPortalResources::Categories.new
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(open(uri))
    
    categories = errorCheck(doc)

    unless categories.nil?
      return categories
    end
    
    categories = {}
    doc.elements.each("*/data/list/categoryBean"){ |element| 
      category = parseCategory(element)
      categories[category[:id].to_s]=category 
    }

    return categories
  end
  
  def self.getGroups
    uri_gen = BioPortalResources::Groups.new
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieve groups"
    LOG.add :debug, uri
    doc = REXML::Document.new(open(uri))
    
    groups = errorCheck(doc)
    unless groups.nil?
      return groups
    end
    
    groups = Groups.new
    groups.group_list = {}
    time = Time.now
    doc.elements.each("*/data/list/groupBean"){ |element| 
      unless element.nil?
        group = parseGroup(element)
        groups.group_list[group[:id]] = group
      end
    }
    puts "getGroups Parse Time: #{Time.now - time}"
    
    return groups
  end
  
  ##
  # Gets a concept node.
  ##
  def self.getNode(params)
    uri_gen = BioPortalResources::Concept.new(params, 500)
    uri = uri_gen.generate_uri
    
    return getConcept(params[:ontology_id], uri)
  end
  
  ##
  # Gets a light version of a concept node. Used for tree browsing.
  ##
  def self.getLightNode(params)
    uri_gen = BioPortalResources::Concept.new(params, 500, true)
    uri = uri_gen.generate_uri
    
    return getConcept(params[:ontology_id], uri)
  end
  
  def self.getTopLevelNodes(params)
    params[:concept_id] = "root"
   
    uri_gen = BioPortalResources::Concept.new(params, 1000)
    uri = uri_gen.generate_uri
    
    LOG.add :debug, "Retrieve top level nodes"
    LOG.add :debug, uri
    doc = open(uri)
    #doc = REXML::Document.new(open(uri))            

    node = errorCheck(doc)         

    unless node.nil?
      return node
    end
    
    timer = Benchmark.ms { node = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "Top level nodes parsed (#{timer})"
    
    return node.children
  end
  
  def self.getOntologyList()
    uri_gen = BioPortalResources::Ontologies.new
    uri = uri_gen.generate_uri
    
    doc = REXML::Document.new(open(uri))
    
    ontologies = errorCheck(doc)
    
    unless ontologies.nil?
      return ontologies
    end
    
    ontologies = []
    doc.elements.each("*/data/list/ontologyBean"){ |element| 
      ontologies << parseOntology(element)
    }

    return ontologies
  end
  
  def self.getActiveOntologyList()
    uri_gen = BioPortalResources::ActiveOntologies.new
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(open(uri))
    
    ontologies = errorCheck(doc)
    
    unless ontologies.nil?
      return ontologies
    end
    
    ontologies = []
    doc.elements.each("*/data/list/ontologyBean"){ |element| 
      ontologies << parseOntology(element)
    }

    return ontologies
  end
  
  def self.getOntologyVersions(params)
    uri_gen = BioPortalResources::OntologyVersions.new(params)
    uri = uri_gen.generate_uri

    doc = REXML::Document.new(open(uri))
    
    ontologies = errorCheck(doc)
    
    unless ontologies.nil?
      return ontologies
    end
    
    ontologies = []
    
    doc.elements.each("*/data/list/ontologyBean"){ |element|  
      ontologies << parseOntology(element)
    }

    return ontologies
  end
  
  def self.getOntology(params)
    uri_gen = BioPortalResources::Ontology.new(params)
    uri = uri_gen.generate_uri

    LOG.add :debug, "Retrieving ontology"
    LOG.add :debug, uri
    doc = REXML::Document.new(open(uri))

    ont = errorCheck(doc)
    
    unless ont.nil?
      return ont
    end
    
    doc.elements.each("*/data/ontologyBean"){ |element|  
      ont = parseOntology(element)
    }

    return ont
  end
  
  ##
  # Used to retrieve data from back-end REST service, then parse from the resulting metrics bean.
  # Returns an OntologyMetricsWrapper object.
  ## 
  def self.getOntologyMetrics(params)
    uri_gen = BioPortalResources::OntologyMetrics.new(params)
    uri = uri_gen.generate_uri
    
    LOG.add :debug, "Retrieving ontology metrics"
    LOG.add :debug, uri
    begin
      doc = REXML::Document.new(open(uri))
    rescue Exception=>e
      LOG.add :debug, "getOntologyMetrics error: #{e.message}"
      return ont
    end
    
    ont = errorCheck(doc)
    
    unless ont.nil?
      return ont
    end
    
    doc.elements.each("*/data/ontologyMetricsBean"){ |element|
      ont = parseOntologyMetrics(element)
    }                    
    
    return ont
  end
  
  def self.getLatestOntology(params)
    uri_gen = BioPortalResources::LatestOntology.new(params)
    uri = uri_gen.generate_uri
    
    doc = REXML::Document.new(open(uri))
    
    ont = errorCheck(doc)
    
    unless ont.nil?
      return ont
    end
    
    doc.elements.each("*/data/ontologyBean"){ |element|  
      ont = parseOntology(element)
    }                    

    return ont 
  end
  
  ##
  # Get a path from a given concept to the root of the ontology.
  ##
  def self.getPathToRoot(params)
    uri_gen = BioPortalResources::PathToRoot.new(params)
    uri = uri_gen.generate_uri
    
    LOG.add :debug, "Retrieve path to root"
    LOG.add :debug, uri
    doc = open(uri)
    
    root = errorCheck(doc)
    
    unless root.nil?
      return root
    end
    
    timer = Benchmark.ms { root = generic_parse(:xml => doc, :type => "NodeWrapper", :ontology_id => params[:ontology_id]) }
    LOG.add :debug, "getPathToRoot Parse Time: #{timer}"
    
    return root
  end

  def self.getNodeNameContains(ontologies,search,page)
    if ontologies.to_s.eql?("0")
      ontologies=""
    else
      ontologies = "ontologyids=#{ontologies.join(",")}&"
        end
 
        LOG.add :debug, BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0&maxnumhits=15"
    begin
     doc = REXML::Document.new(open(BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0&maxnumhits=15"))
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end   

    results = errorCheck(doc)
    
    unless results.nil?
      return results
    end 

    results = []
    doc.elements.each("*/data/page/contents"){ |element|  
      results = parseSearchResults(element)
    }

    pages = 1
    doc.elements.each("*/data/page"){|element|
      pages = element.elements["numPages"].get_text.value
    }
    
    return results,pages
  end

  def self.getUsers()
    uri_gen = BioPortalResources::Users.new
    uri = uri_gen.generate_uri
    
    doc = REXML::Document.new(open(uri))
    
    results = errorCheck(doc)
    
    unless results.nil?
      return results
    end

    results = []          
    doc.elements.each("*/data/list/userBean"){ |element|  
      results << parseUser(element)
    }

    return results
  end
  
  def self.getUser(params)
    uri_gen = BioPortalResources::User.new(params)
    uri = uri_gen.generate_uri
    
    doc = REXML::Document.new(open(uri))
    
    user = errorCheck(doc)
    
    unless user.nil?
      return user
    end
    
    doc.elements.each("*/data/userBean"){ |element|  
      user = parseUser(element)
    }

    return user
  end
  
  def self.authenticateUser(username,password)
    uri_gen = BioPortalResources::Auth.new(:username => username, :password => password)
    uri = uri_gen.generate_uri
    
    begin
      doc = REXML::Document.new(open(uri))
    rescue Exception=>e
      doc = REXML::Document.new(e.io.read)
    end

    user = errorCheck(doc)
    
    unless user.nil?
      return user
    end
    
    doc.elements.each("*/data/userBean"){ |element|  
      user = parseUser(element)
      user.session_id = doc.elements["success"].elements["sessionId"].get_text.value
    }
    
    return user
  end
  
  def self.createUser(params)
    uri_gen = BioPortalResources::CreateUser.new
    uri = uri_gen.generate_uri
    
    begin
      doc = REXML::Document.new(postToRestlet(uri, params))
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end

    user = errorCheck(doc)
    
    unless user.nil?
      return user
    end
    
    doc.elements.each("*/data/userBean"){ |element|  
      user = parseUser(element)
    }
    
    return user
  end
  
  def self.updateUser(params,id)
    uri_gen = BioPortalResources::UpdateUser.new
    uri = uri_gen.generate_uri
    
    begin
      doc = REXML::Document.new(putToRestlet(uri, params))
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end

    user = errorCheck(doc)
    
    unless user.nil?
      return user
    end
    
    doc.elements.each("*/data/userBean"){ |element|  
      user = parseUser(element)
    }

    return user
  end  
  
  def self.createOntology(params)
    uri_gen = BioPortalResources::CreateOntology.new
    uri = uri_gen.generate_uri
    
    begin
      response = postMultiPart(uri, params)
      doc = REXML::Document.new(response)
    rescue Exception=>e
      doc =  REXML::Document.new(e.io.read)
    end

    ontology = errorCheck(doc)
    
    unless ontology.nil?
      return ontology
    end
    
    doc.elements.each("*/data/ontologyBean"){ |element|  
      ontology = parseOntology(element)
    }
    
    return ontology
  end
  
  def self.updateOntology(params,version_id)
    uri_gen = BioPortalResources::UpdateOntology.new(:ontology_id => version_id)
    uri = uri_gen.generate_uri
    
    begin
      doc = REXML::Document.new(putToRestlet(uri, params))
    rescue Exception=>e
      doc = REXML::Document.new(e.io.read)
      
    end
    
    ontology = errorCheck(doc)
    
    unless ontology.nil?
      return ontology
    end
    
    doc.elements.each("*/data/ontologyBean"){ |element|  
      ontology = parseOntology(element)
    }
    
    return ontology          
    
  end
  
  def self.download(ontology_id)
    uri_gen = BioPortalResources::DownloadOntology.new(:ontology_id => ontology_id)
    return uri_gen.generate_uri
  end
  
  def self.getDiffs(ontology_id)
    uri_gen = BioPortalResources::Diffs.new(:ontology_id => ontology_id)
    uri = uri_gen.generate_uri
    
    begin
      doc = REXML::Document.new(open(uri))
    rescue Exception=>e
      doc = REXML::Document.new(e.io.read)
    end   
    
    results = errorCheck(doc)
    
    unless results.nil?
      return results
    end          
    
    pairs = []
    doc.elements.each("*/data/list") { |pair|
      pair.elements.each{|list|
        pair = []
        list.elements.each{|item|
          pair << item.get_text.value
        }
        pairs << pair
      }            
    }
    return pairs
  end
  
  def self.diffDownload(ver1,ver2)          
    uri_gen = BioPortalResources::DownloadDiffs.new( :ontology_version1 => ver1, :ontology_version2 => ver2 )
    return uri_gen.generate_uri
  end
  
private
  
  def self.getConcept(ontology, concept_uri)    
    begin
#      LOG.add :debug, "Concept retreive url"
#      LOG.add :debug, concept_uri
      startTime = Time.now
      rest = open(concept_uri)
#      LOG.add :debug, "Concept retreive (#{Time.now - startTime})"
    rescue Exception=>e
#      LOG.add :debug, "getConcept retreive error: #{e.message}"
    end
    
    begin
      startTime = Time.now
      parser = XML::Parser.io(rest)
      doc = parser.parse
#      LOG.add :debug, "Concept parse (#{Time.now - startTime})"
    rescue Exception=>e
#      LOG.add :debug, "getConcept parse error: #{e.message}"
    end
    
    if doc.nil?
      return doc
    end
    
    node = errorCheckLibXML(doc)
    
    unless node.nil?
      return node
    end
    
    startTime = Time.now
    doc.find("/*/data/classBean").each{ |element|  
      node = parseConceptLibXML(element,ontology)
    }
#    LOG.add :debug, "Concept storage (#{Time.now - startTime})"
    
    return node
  end
  
  def self.postMultiPart(url, paramsHash)
    params=[]
    for param in paramsHash.keys
      if paramsHash["isRemote"].eql?("0") && param.eql?("filePath")
        params << file_to_multipart('filePath',paramsHash["filePath"].original_filename,paramsHash["filePath"].content_type,paramsHash["filePath"])
      else
        params << text_to_multipart(param,paramsHash[param])
      end
      
    end
    
    boundary = '349832898984244898448024464570528145'
    query = 
    params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"
    uri = URI.parse(url)
    response = Net::HTTP.new(uri.host,$REST_PORT).start.
    post2(uri.path,
          query,
            "Content-type" => "multipart/form-data; boundary=" + boundary)
    
    return response.body
  end
  
  def self.text_to_multipart(key, value)
    if value.class.to_s.downcase.eql?("array")
      return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" + 
            "\r\n" + 
            "#{value.join(",")}\r\n"
    else
      return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" + 
            "\r\n" + 
            "#{value}\r\n"
    end
  end
  
  def self.file_to_multipart(key, filename, mime_type,content)
    return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
            "Content-Transfer-Encoding: base64\r\n" +
            "Content-Type: text/plain\r\n" + 
            "\r\n" + content.read() + "\r\n"
  end
  
  def self.postToRestlet(url, paramsHash)
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end
    res = Net::HTTP.post_form(URI.parse(url),paramsHash)
    return res.body
  end
  
  def self.putToRestlet(url, paramsHash)
    paramsHash["applicationid"] = $APPLICATION_ID
    paramsHash["method"]="PUT"
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end
    res = Net::HTTP.post_form(URI.parse(url),paramsHash)
    return res.body
  end

  def self.parseSearchResults(searchContents)
    
    searchResults =[]
    searchResultList = searchContents.elements["searchResultList"]
    
    searchResultList.elements.each("searchBean"){|searchBean|
      search_item = {}
      search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
      search_item[:ontologyVersionId]=searchBean.elements["ontologyVersionId"].get_text.value.strip
      search_item[:ontologyId]=searchBean.elements["ontologyId"].get_text.value.strip
      search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
      search_item[:recordType]=searchBean.elements["recordType"].get_text.value.strip
      search_item[:conceptId]=searchBean.elements["conceptId"].get_text.value.strip
      search_item[:conceptIdShort]=searchBean.elements["conceptIdShort"].get_text.value.strip
      search_item[:preferredName]=searchBean.elements["preferredName"].get_text.value.strip
      search_item[:contents]=searchBean.elements["contents"].get_text.value.strip
      searchResults<< search_item
    }
    
    return searchResults
  end

  def self.parseCategory(categorybeanXML)
    category ={}
    category[:name]=categorybeanXML.elements["name"].get_text.value.strip rescue ""
    category[:id]=categorybeanXML.elements["id"].get_text.value.strip rescue ""
    category[:parentId]=categorybeanXML.elements["parentId"].get_text.value.strip rescue ""    
    return category
  end
  
  def self.parseGroup(groupbeanXML)
    group = {}
    group[:id] = groupbeanXML.elements["id"].get_text.value.strip.to_i rescue ""
    group[:name] = groupbeanXML.elements["name"].get_text.value.strip rescue ""
    group[:acronym] = groupbeanXML.elements["acronym"].get_text.value.strip rescue ""
    
    return group
  end
  
  ##
  # Parse user data from the returned XML.
  ##
  def self.parseUser(userbeanXML)
    user = UserWrapper.new
    
    user.id = userbeanXML.elements["id"].get_text.value.strip
    user.username = userbeanXML.elements["username"].get_text.value.strip
    user.email = userbeanXML.elements["email"].get_text.value.strip
    user.firstname = userbeanXML.elements["firstname"].get_text.value.strip rescue ""
    user.lastname = userbeanXML.elements["lastname"].get_text.value.strip rescue ""
    user.phone = userbeanXML.elements["phone"].get_text.value.strip rescue ""
    
    roles = []  
    begin
      userbeanXML.elements["roles"].elements.each("string"){ |role|
        roles << role.get_text.value.strip
      } 
    rescue Exception=>e
      LOG.add :debug, e.inspect
    end
    
    user.roles = roles
    
    return user
  end
  
  def self.parseOntology(ontologybeanXML)
    
    ontology = OntologyWrapper.new
    ontology.id = ontologybeanXML.elements["id"].get_text.value.strip
    ontology.displayLabel= ontologybeanXML.elements["displayLabel"].get_text.value.strip rescue "No Label"
    ontology.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip
    ontology.userId = ontologybeanXML.elements["userId"].get_text.value.strip rescue ""
    ontology.parentId = ontologybeanXML.elements["parentId"].get_text.value.strip rescue ""
    ontology.format = ontologybeanXML.elements["format"].get_text.value.strip rescue  ""
    ontology.versionNumber = ontologybeanXML.elements["versionNumber"].get_text.value.strip rescue ""
    ontology.internalVersion = ontologybeanXML.elements["internalVersionNumber"].get_text.value.strip
    ontology.versionStatus = ontologybeanXML.elements["versionStatus"].get_text.value.strip rescue ""
    ontology.isCurrent = ontologybeanXML.elements["isCurrent"].get_text.value.strip rescue ""
    ontology.isRemote = ontologybeanXML.elements["isRemote"].get_text.value.strip rescue ""
    ontology.isReviewed = ontologybeanXML.elements["isReviewed"].get_text.value.strip rescue ""
    ontology.statusId = ontologybeanXML.elements["statusId"].get_text.value.strip rescue ""
    ontology.dateReleased =  Date.parse(ontologybeanXML.elements["dateReleased"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.contactName = ontologybeanXML.elements["contactName"].get_text.value.strip rescue ""
    ontology.contactEmail = ontologybeanXML.elements["contactEmail"].get_text.value.strip rescue ""
    ontology.urn = ontologybeanXML.elements["urn"].get_text.value.strip rescue ""
    ontology.isFoundry = ontologybeanXML.elements["isFoundry"].get_text.value.strip rescue ""
    ontology.isManual = ontologybeanXML.elements["isManual"].get_text.value.strip rescue ""
    ontology.filePath = ontologybeanXML.elements["filePath"].get_text.value.strip rescue ""
    ontology.homepage = ontologybeanXML.elements["homepage"].get_text.value.strip rescue ""
    ontology.documentation = ontologybeanXML.elements["documentation"].get_text.value.strip rescue ""
    ontology.publication = ontologybeanXML.elements["publication"].get_text.value.strip rescue ""
    ontology.dateCreated = Date.parse(ontologybeanXML.elements["dateCreated"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.preferredNameSlot = ontologybeanXML.elements["preferredNameSlot"].get_text.value.strip rescue ""
    ontology.synonymSlot = ontologybeanXML.elements["synonymSlot"].get_text.value.strip rescue ""
    ontology.description = ontologybeanXML.elements["description"].get_text.value.strip rescue ""
    ontology.abbreviation = ontologybeanXML.elements["abbreviation"].get_text.value.strip rescue ""    
    ontology.targetTerminologies = ontologybeanXML.elements["targetTerminologies"].get_text.value.strip rescue ""    
    
    ontology.categories = []
    ontologybeanXML.elements["categoryIds"].elements.each do |element|
      ontology.categories<< element.get_text.value.strip
    end
    
    ontology.groups = []
    ontologybeanXML.elements["groupIds"].elements.each do |element|
      ontology.groups << element.get_text.value.strip.to_i
    end
    
    # View-related parsing
    ontology.isView = ontologybeanXML.elements["isView"].get_text.value.strip rescue "" 
    ontology.viewOnOntologyVersionId = ontologybeanXML.elements['viewOnOntologyVersionId'].elements['int'].get_text.value rescue "" 
    ontology.viewDefinition = ontologybeanXML.elements["viewDefinition"].get_text.value.strip rescue "" 
    ontology.viewGenerationEngine = ontologybeanXML.elements["viewGenerationEngine"].get_text.value.strip rescue "" 
    ontology.viewDefinitionLanguage = ontologybeanXML.elements["viewDefinitionLanguage"].get_text.value.strip rescue "" 
    
    ontology.view_ids = []
    ontology.virtual_view_ids=[]
    begin
      ontologybeanXML.elements["hasViews"].elements.each{|element|
        ontology.view_ids << element.get_text.value.strip
      }
      ontologybeanXML.elements['virtualViewIds'].elements.each{|element|
        ontology.virtual_view_ids << element.get_text.value.strip
      }
    rescue
    end
    
    return ontology
  end
  
  ##
  # Parses data from the ontology metrics bean XML, returns an OntologyMetricsWrapper object.
  ##
  def self.parseOntologyMetrics(ontologybeanXML)
    
    ontologyMetrics = OntologyMetricsWrapper.new
    ontologyMetrics.id = ontologybeanXML.elements["id"].get_text.value.strip rescue ""
    ontologyMetrics.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip rescue ""
    ontologyMetrics.numberOfAxioms = ontologybeanXML.elements["numberOfAxioms"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfClasses = ontologybeanXML.elements["numberOfClasses"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfIndividuals = ontologybeanXML.elements["numberOfIndividuals"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfProperties = ontologybeanXML.elements["numberOfProperties"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumDepth = ontologybeanXML.elements["maximumDepth"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumNumberOfSiblings = ontologybeanXML.elements["maximumNumberOfSiblings"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.averageNumberOfSiblings = ontologybeanXML.elements["averageNumberOfSiblings"].get_text.value.strip.to_i rescue ""
    
    begin
      ontologybeanXML.elements["classesWithOneSubclass"].elements.each { |element|
        ontologyMetrics.classesWithOneSubclass << element.get_text.value.strip
        unless defined? first
          ontologyMetrics.classesWithOneSubclassAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithOneSubclassLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
          element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }
      
      ontologybeanXML.elements["classesWithMoreThanXSubclasses"].elements.each { |element|
        class_name = element.elements['string[1]'].get_text.value
        class_count = element.elements['string[2]'].get_text.value.to_i
        ontologyMetrics.classesWithMoreThanXSubclasses[class_name] = class_count
        unless defined? first
          ontologyMetrics.classesWithMoreThanXSubclassesAll = element.elements['string[1]'].get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithMoreThanXSubclassesLimitPassed = element.elements['string[1]'].get_text.value.strip.include?("limitpassed") ? 
          element.elements['string[2]'].get_text.value.strip.to_i : false
          first = false
        end
      }
      
      ontologybeanXML.elements["classesWithNoDocumentation"].elements.each { |element|
        ontologyMetrics.classesWithNoDocumentation << element.get_text.value.strip
        unless defined? first
          ontologyMetrics.classesWithNoDocumentationAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithNoDocumentationLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
          element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }
      
      ontologybeanXML.elements["classesWithNoAuthor"].elements.each { |element|
        ontologyMetrics.classesWithNoAuthor << element.get_text.value.strip
        unless defined? first
          ontologyMetrics.classesWithNoAuthorAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithNoAuthorLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
          element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }
      
      ontologybeanXML.elements["classesWithMoreThanOnePropertyValue"].elements.each { |element|
        ontologyMetrics.classesWithMoreThanOnePropertyValue << element.get_text.value.strip
        unless defined? first
          ontologyMetrics.classesWithMoreThanOnePropertyValueAll = element.get_text.value.strip.eql?("alltriggered")
          ontologyMetrics.classesWithMoreThanOnePropertyValueLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
          element.get_text.value.strip.split(":")[1].to_i : false
          first = false
        end
      }
      
      # Stop exception checking
    rescue Exception=>e
      LOG.add :debug, e.inspect
    end
    
    return ontologyMetrics
  end
  
  def self.errorCheck(doc)
    response = nil
    errorHolder = {}
    begin
      doc.elements.each("org.ncbo.stanford.bean.response.ErrorStatusBean"){ |element|  
        errorHolder[:error] = true
        errorHolder[:shortMessage] = element.elements["shortMessage"].get_text.value.strip
        errorHolder[:longMessage] = element.elements["longMessage"].get_text.value.strip
        response = errorHolder
      }
    rescue
    end
    
    return response
  end
  
  def self.errorCheckLibXML(doc)
    response = nil
    errorHolder={}
    begin
      doc.elements.each("org.ncbo.stanford.bean.response.ErrorStatusBean"){ |element|  
        errorHolder[:error] = true
        errorHolder[:shortMessage] = element.elements["shortMessage"].get_text.value.strip
        errorHolder[:longMessage] =element.elements["longMessage"].get_text.value.strip
        response = errorHolder
      }
    rescue
    end
    
    return response
  end
  
  def self.parseConcept(classbeanXML, ontology)
    node = NodeWrapper.new
    node.child_size=0
    node.id = classbeanXML.elements["id"].get_text.value
    node.fullId = classbeanXML.elements["fullId"].get_text.value rescue ""
    
    node.name = classbeanXML.elements["label"].get_text.value rescue node.id
    node.version_id = ontology
    node.children = []
    node.properties = {}
    classbeanXML.elements["relations"].elements.each("entry"){ |entry|
      
      startGet = Time.now
      case entry.elements["string"].get_text.value.strip
        when SUBCLASS
        if entry.elements["list"].attributes["reference"]
          entry.elements["list"].elements.each(entry.elements["list"].attributes["reference"]){|element|
            element.elements.each{|classbean|
              
              #issue with using reference.. for some reason pulls in extra guys sometimes
              if classbean.name.eql?("classBean")
                node.children<<parseConcept(classbean,ontology)
                         end
                         }
                     }
                   
                else
                  entry.elements["list"].elements.each {|element|
                      node.children<<parseConcept(element,ontology)
                  } 
                end                
               when SUPERCLASS
              
               when CHILDCOUNT
                 node.child_size = entry.elements["int"].get_text.value.to_i
               else                
                 begin
                 node.properties[entry.elements["string"].get_text.value] = entry.elements["list"].elements.map{|element| 
                   if(element.name.eql?("classBean"))
                      parseConcept(element,ontology).name                    
                   else 
                    element.get_text.value unless element.get_text.value.empty? 
                    
                   end}.join(" | ") #rescue ""
                  rescue Exception =>e
                  end
               end
        }
        
        node.children.sort!{|x,y| x.name.downcase<=>y.name.downcase}
        
        return node
  end

  def self.parseConceptLibXML(classbeanXML, ontology)
    # check if we're at the root node
    root = classbeanXML.path == "/success/data/classBean" ? true : false

    # Get basic info and initialize the node.
    node = getConceptBasicInfo(classbeanXML,ontology)
     
    if root
      # look for child nodes and process if found
      search = classbeanXML.path + "/relations/entry[string='SubClass']/list/classBean"
      results = classbeanXML.first.find(search)
      unless results.empty?
        results.each do |child|
          node.children << parseConceptLibXML(child,ontology)
        end
      end
    end
          
    if root       
      # find all other properties
      search = classbeanXML.path + "/relations/entry"
      classbeanXML.first.find(search).each do |entry|
        # check to see if the entry is a relationship (signified by [R]), if it is move on
        if classbeanXML.first.find(entry.path + "/string").first.content[0,3].eql?("[R]") ||
                classbeanXML.first.find(entry.path + "/string").first.content[0,10].eql?("SuperClass")
          next
        end
        
        # check to see if this entry has a list of classBeans
        beans = classbeanXML.first.find(entry.path + "/list/classBean")
        list_content = []
        if !beans.empty?
          beans.each do |bean|
            bean_label = classbeanXML.first.find(bean.path + "/label")
            list_content << bean_label.first.content unless bean_label.first.nil?
          end
        else
          # if there's no classBeans, process the list normally
          list = classbeanXML.first.find(entry.path + "/list/string")
          list.each do |item|
            list_content << item.content
          end
        end
        
        node.properties[classbeanXML.first.find(entry.path + "/string").first.content] = list_content.join(" | ")
      end # stop processing relation entries
    end # stop root node processing
     
    node.children.sort!{|x,y| x.name.downcase<=>y.name.downcase}
    return node
  end
  
  def self.buildPathToRootTree(classbeanXML, ontology)

    node = getConceptBasicInfo(classbeanXML, ontology)
    
    # look for child nodes and process if found
    search = classbeanXML.path + "/relations/entry[string='SubClass']/list/classBean"
    results = classbeanXML.first.find(search)
    unless results.empty?
      results.each do |child|
        # If we're about to process a path we've seen, don't continue.
        if @seen_paths[child.path]
          next
        end
        @seen_paths[child.path] = 1
        node.children << buildPathToRootTree(child,ontology)
        node.children.sort! { |a,b| a.name.downcase <=> b.name.downcase }
      end
    end
    
    return node
  end
  
  def self.getConceptBasicInfo(classbeanXML, ontology)
    # build a node object
    node = NodeWrapper.new
    # set default child size
    node.child_size=0
    # get node.id
    id = classbeanXML.first.find(classbeanXML.path + "/id")
    node.id = id.first.content unless id.first.nil?
    # get fullId
    fullId = classbeanXML.first.find(classbeanXML.path + "/fullId")
    node.fullId = fullId.first.content unless fullId.first.nil?
    # get label
    label = classbeanXML.first.find(classbeanXML.path + "/label")
    node.name = label.first.content unless label.first.nil?
    # get type
    type = classbeanXML.first.find(classbeanXML.path + "/type")
    node.type = type.first.content unless type.first.nil?
    # get childcount info
    childcount = classbeanXML.first.find(classbeanXML.path + "/relations/entry[string='ChildCount']/int")
    node.child_size = childcount.first.content.to_i unless childcount.first.nil?
    # get isBrowsable info
    node.is_browsable = node.type.downcase.eql?("class") rescue ""
    # get synonyms
    synonyms = classbeanXML.first.find(classbeanXML.path + "/synonyms/string")
    node.synonyms = []
    synonyms.each do |synonym|
      node.synonyms << synonym.content
    end
    # get definitions
    definitions = classbeanXML.first.find(classbeanXML.path + "/definitions/string")
    node.definitions = []
    definitions.each do |definition|
      node.definitions << definition.content
    end
    
     
    node.version_id = ontology
    node.children = []
    node.properties = {}
      
    return node
  end
  
  ###################### Generic Parser #########################
  ## The following methods are part of a generic parser, which
  ## promises a simpler, faster parsing implementation. For now
  ## these methods are contained here, but future plans would
  ## bring the parser into the models, making it so that data
  ## is defined and dealt with in one location.
  ##
  ## Right now a hash is produced that matches the provided REST XML.
  ## When calling generic_parse you can provide the model type
  ## (NodeWrapper, OntologyWrapper, etc) and then overwrite the
  ## model's intialize method to convert the hash into a proper object.
  ## For an example, see the NodeWrapper model and getPathToRoot method.
  ##
  ## Parameters
  ## :type => object type
  ## :xml => IO object containing XML data
  ## Additional parameters can be added and will be passed to the model initializer
  ##
  ## Usage
  ## generic_parse(:xml => xml, :type => "OntologyWrapper", :ontology_id => ontology_id
  ####
  def self.generic_parse(params)
    type = params[:type] rescue nil
    xml = params[:xml]
    
    parser = XML::Parser.io(xml, :options => LibXML::XML::Parser::Options::NOBLANKS)
    doc = parser.parse
    root = doc.find_first("/success/data")
    parsed = self.parse(root)
    # We end up with an extra hash at the root, this should get rid of that
    attributes = {}
    parsed.each do |k,v|
      if v.is_a?(Hash)
        attributes = {}
        v.each{ |k,v| attributes[k] = v }
      elsif v.is_a?(Array)
        attributes = v
      end
    end

    if type
      return Kernel.const_get(type).new(attributes, params)
    else
      return attributes
    end
  end
  
  def self.parse(node)
    a = {}
    
    node.each_element do |child|
      case child.name
        when "entry"
          a[child.first.content] = process_entry(child)
        when "list"
          a[node.name] = process_list(child)
        when "int"
          return child.content.to_i
        when "string"
          return child.content
      else
        if !child.first.nil? && child.first.element?
          a[child.name] = parse(child)
        else
          a[child.name] = child.content
        end
      end
    end
    a
  end
  
  # Entries are generally key/value pairs, sometimes the value is a list
  def self.process_entry(entry)
    children = []
    entry.each_element{|c| children << c}

    entry_key = children[0].content
    entry_values = children[1]
    entry_hash = {}
    
    # Check to see if entry contains data as a list or single
    if entry_values.name.eql?("list") && !entry_values.empty?
      values = process_list(entry_values)
      entry_hash[entry_key] = values
    else
      entry_hash[entry_key] = entry_values.content
    end
  end
  
  # Processes a list of items, returns an array of values
  def self.process_list(list)
    return if list.children.empty?
    list_type = list.first.name
    values = []
    
    if list_type.eql?("int")
      list.each{ |entry| values << entry.content.to_i }
    elsif list_type.eql?("string")
      list.each{ |entry| values << entry.content.to_s }
    elsif !list.first.nil? && list.first.element?
      list.each{ |entry| values << parse(entry) }
    else
      list.each{ |entry| values << entry.content }
    end
    values
  end

  
end
