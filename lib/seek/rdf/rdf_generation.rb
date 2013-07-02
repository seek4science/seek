require 'csv'


module Seek
  module Rdf
    module RdfGeneration
      include RightField

      def self.included(base)
        base.after_save :create_rdf_generation_job
      end

      def to_rdf
        rdf_graph = to_rdf_graph
        RDF::Writer.for(:rdfxml).buffer(:prefixes=>ns_prefixes) do |writer|
          rdf_graph.each_statement do |statement|
            writer << statement
          end
        end
      end

      def to_rdf_graph
        rdf_graph = handle_rightfield_contents self
        rdf_graph = describe_type(rdf_graph)
        rdf_graph = generate_from_csv_definitions rdf_graph
        rdf_graph = additional_triples rdf_graph
        rdf_graph
      end

      def handle_rightfield_contents object
        if (object.respond_to?(:contains_extractable_spreadsheet?) && contains_extractable_spreadsheet? && content_blob.is_xls?)
          generate_rightfield_rdf_graph(self)
        else
          RDF::Graph.new
        end
      end

      def rdf_resource
        uri = Seek::Config.site_base_host+"/#{self.class.name.tableize}/#{self.id}"
        RDF::Resource.new(uri)
      end

      def save_rdf
        #seperate public and private (to an outside user) into separate directories
        if self.can_view?(nil)
          path = public_rdf_storage_path
          other_path = private_rdf_storage_path
        else
          path = private_rdf_storage_path
          other_path = public_rdf_storage_path
        end

        #this is necessary to remove the old rdf if the permissions switched from public to private, or vice-versa
        FileUtils.rm other_path if File.exists?(other_path)

        File.open(path,"w") do |f|
          f.write(self.to_rdf)
          f.flush
        end
        path
      end

      private

      def private_rdf_storage_path
        rdf_storage_path "private"
      end

      def public_rdf_storage_path
        rdf_storage_path "public"
      end

      def rdf_storage_path inner_dir
        path = File.join(Seek::Config.rdf_filestore_path,inner_dir)
        if !File.exists?(path)
          FileUtils.mkdir_p(path)
        end
        unique_id="#{self.class.name}-#{self.id}"
        filename = "#{unique_id}.rdf"
        File.join(path,filename)
      end


      #extra steps that cannot be easily handled by the csv template
      def additional_triples rdf_graph
        if self.is_a?(Model) && self.contains_sbml?
          rdf_graph << [self.rdf_resource,JERMVocab.hasFormat,JERMVocab.SBML_format]
        end
        rdf_graph
      end

      def generate_from_csv_definitions rdf_graph
        #load template
        path_to_template=File.join(File.dirname(__FILE__), "rdf_mappings.csv")
        rows = Rails.cache.fetch("rdf_definitions",:expires_in=>1.hour) do
          CSV.read(path_to_template)
        end
        rows.each do |row|
          unless row[0].downcase=="class"
            klass=row[0].strip
            method=row[1]
            property=row[2]
            uri_or_literal=row[3].downcase
            transform=row[4]
            collection_transform=row[5]
            if (klass=="*" || self.class.name==klass) && self.respond_to?(method)
              rdf_graph = generate_triples(self,method,property,uri_or_literal,transform,collection_transform,rdf_graph)
            elsif self.class.name==klass #matched the class but the method isnt found
              puts "WARNING: Expected to find method #{method} for class #{klass}"
            end
          end
        end
        rdf_graph
      end

      def generate_triples subject, method, property,uri_or_literal,transformation,collection_transform,rdf_graph
        resource = subject.rdf_resource
        transform = transformation.strip unless transformation.nil?
        collection_transform = collection_transform.strip unless collection_transform.nil?
        items = subject.send(method)
        items = [items] unless items.kind_of?(Array) #may be an array of items or a single item. Cant use Array(item) here cos it screws up timezones and strips out nils
        unless collection_transform.blank?
          items = eval("items.#{collection_transform}")
        end
        items.each do |item|
          property_uri = eval(property)
          if !transformation.blank?
            item = eval(transformation)
          end
          o = if uri_or_literal.downcase=="u"
                if item.respond_to?(:rdf_resource)
                  item.rdf_resource
                else
                  RDF::Resource.new(item)
                end
          else
            item.nil? ? "" : item
          end
          rdf_graph << [resource,property_uri,o]
        end
        rdf_graph
      end

      def describe_type rdf_graph
       it_is = JERMVocab.for_type self
       unless it_is.nil?
         resource = self.rdf_resource
         rdf_graph <<  [resource,RDF.type,it_is]
       end
       rdf_graph
      end

      #the hash of namespace prefixes to pass to the RDF::Writer when generating the RDF
      def ns_prefixes
        {
            "jerm"=>JERMVocab.to_uri.to_s,
            "dcterms"=>RDF::DC.to_uri.to_s,
            "owl"=>RDF::OWL.to_uri.to_s,
            "foaf"=>RDF::FOAF.to_uri.to_s,
            "sioc"=>RDF::SIOC.to_uri.to_s,
            "owl"=>RDF::OWL.to_uri.to_s,
        }
      end

      def create_rdf_generation_job
        unless (self.changed - ["updated_at","last_used_at"]).empty?
          RdfGenerationJob.create_job self
        end
      end

    end
  end
end
