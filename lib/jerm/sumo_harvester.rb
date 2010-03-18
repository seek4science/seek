module Jerm
  class SumoHarvester < WikiHarvester        
    
    attr_accessor :test
    
    def changed_since(date)
      @changed_since_date = date #TODO: use this for something
      
      @visited_links = Array.new
      @resources = Array.new
      @searched_uris = Array.new    
      
      get_links(@base_uri, 0)
      return @resources.uniq
    end

    def construct_resource resource
      #already is of type Resource
      return resource
    end
  
    private
    
    #Get links from a page and search them for experiment templates
    def get_links(target, level)
      links = Array.new
      uri=URI.parse(target)
      doc = uri.open(:http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      doc.search("/html/body/div#main/div#content//a").each do |e|
        uri = e.attributes['href']
        if uri.start_with?("/trac/wiki/LIMS/Experiments/")
          links << complete_url(uri, extract_base_url(target))
        end      
      end
      
      links.uniq.each do |link|
        @data_files = Array.new
        @sops = Array.new
        @experimenters = Array.new
        @section = "none"
        @title = ""
        @author = ""
        @date = ""
        @table = 0
        @valid_template = false
        @stop_search = false
        unless @visited_links.include?(link)
          @visited_links << link
          get_data(link, (level+1))
        end
      end
    end
    
    def get_data(uri, level)    
      #Open the page, using the http authentication
      doc = open(uri, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      #Get all of the tags
      doc.search("/html/body/div#main/div#content//").each do |e|
        break if @stop_search
        case e.name
          when "p"
            if e.attributes['class'] == "path"
              @section = "path"
            end
          when "h1"
            @title += " " + e.inner_html
            @title.strip!
          when "h2", "h3"
            @section = e.inner_html.strip
          when "table"
            @table += 1
            if @section == "General Data" || @table == 1
              @valid_template = true
              general_data = {}
              rows = e.search("//tr")
              #Make a hash with the items from the first column as the key
              # and the items from the second column as the value
              rows.each do |row|
                cols = row.search("//td")
                general_data[cols.first.inner_html.strip.downcase.gsub(/<(\/)?(.)>/,"")] = cols.last.inner_html.strip 
              end
              
              general_data.each_key do |k|
                if k.start_with?("author")                  
                  @author = general_data[k].strip
                  #to deal with awkward author fields like "<Name> (<Job that they did>)"                  
                  @author = @author[0...(@author =~ (/[^-a-zA-Z ]/))].strip if @author =~ (/[^-a-zA-Z ]/)
                elsif k.downcase.start_with?("date")
                  @date = general_data[k]           
                elsif k.downcase.start_with?("access")
                  @stop_search = general_data[k].include?("NoData")
                  @valid_template = false if @stop_search
                end              
              end
              
            end
            
            if @section == "Experimenters"
              #Get the experimenters names from the table (1st column)
              rows = e.search("//tr")
              rows.each do |row|
                unless row == rows.first
                  cols = row.search("//td")
                  cell = cols[0].inner_html.strip
                  if cell =~ /[a-zA-Z]+/
                    @experimenters << cell 
                  end
                end
              end
            end
            
            if @section == "Applied SOPs"
              rows = e.search("//tr")
              rows.each do |row|
                #skip first row (titles)
                unless row == rows.first
                  cols = row.search("//td")
                  #Get the SOP names from the table (1st column)              
                  cell = cols[0]
                  #Get the URL to the SOP from the table cell
                  sop_link = cell.at("a")
                  unless sop_link.nil?
                    resource_uri = complete_url(sop_link['href'], extract_base_url(uri))                    
                    @sops << resource_uri unless @searched_uris.include?(resource_uri)
                    @searched_uris << resource_uri
                  end
                end
              end
            end
          
          #Get the attached data files from the links with class 'attachment'
          when "a"
            if @section == "path" && e.inner_html.start_with?("WP")
              @WP = e.inner_html.split("WP").last.to_f / 10            
            end
            unless e.attributes['href'].nil?
              resource_uri = e.attributes['href']    
              #sort out relative paths
              resource_uri = complete_url(resource_uri.gsub("/attachment/","/raw-attachment/"), extract_base_url(uri))
              
              #Don't visit timeline links, anchors, or pages already visited.
              unless (resource_uri.include?("timeline?") || resource_uri.start_with?("#") || @searched_uris.include?(resource_uri))
                #Remember we've visited this link
                if @section == "Attachments"
                  @data_files << resource_uri
                  @searched_uris << resource_uri
                elsif e.attributes['class'] == "attachment" && (self.test == 1)
                  @data_files << resource_uri
                  @searched_uris << resource_uri
                end
      
              end        
            end          
        end
      end
      
      #If we're on a valid experiment page..
      if @valid_template
        #Create sop resources
        unless @sops.empty?
          @sops.uniq.each do |s|
            res = SumoResource.new
            res.uri = s
            res.type = "Sop"
            res.work_package = @WP
            res.experimenters = @experimenters
            sop_data = parse_sop(s)
            title, author = sop_data[:title], sop_data[:author]
            unless author.nil?
              first_name, last_name = author.split(" ", 2)
              res.author_first_name = first_name
              res.author_last_name = last_name
            end
            res.title = title
            @resources << res
          end
        end
        
        #Create data file resources
        unless @data_files.empty?
          @data_files.uniq.each do |s|
            res = SumoResource.new
            res.uri = s
            res.type = "DataFile"
            res.work_package = @WP
            res.experimenters = @experimenters.uniq
            unless @author.nil?
              first_name, last_name = @author.split(" ", 2)
              res.author_first_name = first_name
              res.author_last_name = last_name
            end
            @resources << res
          end
        end 
      #Otherwise follow other links
      else
        get_links(uri, level)
      end
    end
    
    def parse_sop(uri)
      doc = open(uri, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      params = {}
      stop_search = false
      #Get all of the tags
      doc.search("/html/body/div#main/div#content//").each do |e|
        break if stop_search
        case e.name
          when "h1"
            unless params[:title]
              params[:title] = e.inner_html
              params[:title].strip!
            end
          when "table"
            unless params[:author]
              data = {}
              rows = e.search("//tr")
              #Make a hash with the items from the first column as the key
              # and the items from the second column as the value
              rows.each do |row|
                cols = row.search("//td")
                data[cols.first.inner_html.strip.gsub(/<(\/)?(.)>/,"")] = cols.last.inner_html.strip 
              end 
              
              data.each_key do |k|
                if k.downcase.start_with?("author")                  
                  params[:author] = data[k].split(",").first
                elsif k.downcase.start_with?("access")
                  stop_search = data[k].include?("NoData")
                end  
              end
            end
        end
      end  
      
      if stop_search
        return nil
      else
        return params
      end
    end
    
  end
end