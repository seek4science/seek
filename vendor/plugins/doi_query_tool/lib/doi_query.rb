require 'rubygems'
require 'xml'
require 'open-uri'

class DoiQuery
  attr_accessor :api_key
  
  FETCH_URL = "http://www.crossref.org/openurl/"
  
  def initialize(a)
    self.api_key = a    
  end
  
  #Takes either a DOI and fetches the associated publication
  def fetch(id, params = {})
    begin
      params[:format] = "unixref"
      params[:id] = "doi:"+id unless params[:id]
      params[:pid] = self.api_key unless params[:pid]
      params[:noredirect] = true
      url = FETCH_URL + "?" + params.delete_if{|k,v| k.nil?}.to_param
      
      doc = query(url)  
      
      return parse_xml(doc)
    rescue
      raise
    end 
  end
  
  #Parses the XML returned from the DOI query, and creates an object
  def parse_xml(doc)
    begin
      article = doc.find_first("//journal")    
      params = {}
      
      params[:doc] = article
      
      title = article.find_first('//journal_article/titles/title')
      params[:title] = title.nil? ? nil : title.content
      
      params[:authors] = []
      article.find('//contributors/person_name').each do |author|
        author_last_name = author.find_first(".//surname").content
        author_first_name = author.find_first(".//given_name").content
        params[:authors] << DoiAuthor.new(author_first_name, author_last_name)
      end
      
      journal = article.find_first('//journal_metadata/abbrev_title')
      params[:journal] = journal.nil? ? nil : journal.content
      
      date = article.find_first('//publication_date')
      params[:pub_date] = date.nil? ? nil : parse_date(date)
      
      params[:doi] = article.find_first('//doi_data/doi').content
      
      return DoiRecord.new(params)
    rescue Exception => ex
      raise "Unknown document structure\n#{ex.backtrace.join("\n")}"
    end
  end
  
  private
  
  def query(url)
    begin
      doc = open(url)
      #Manually remove annoying namespaces because libxml can't do it
      string = doc.read
      string = string.gsub(/xmlns=\"([^\"]*)\"/,"")    
      doc = XML::Parser.string(string).parse
      return doc
    rescue Exception => ex
      raise "There was an error fetching the given DOI\n#{ex.backtrace.join("\n")}"
    end
  end
  
  def parse_date(xml_date)
    if xml_date.nil?
      return nil
    else
      day = xml_date.find_first(".//day")
      day = day.nil? ? "01" : day.content
      month = xml_date.find_first(".//month")
      month = month.nil? ? "01" : month.content
      year = xml_date.find_first(".//year")
      year = year.nil? ? "1970" : year.content
      date = "#{month}/#{day}/#{year}".to_date
      return date
    end
  end
end