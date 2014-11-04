module Seek
  module Ontologies
    module Controller
      module TypeHandler
        extend ActiveSupport::Concern
        included do
          before_filter :find_ontology_type_class, only: [:show]
          before_filter :find_and_authorize_assays, only: [:show]
        end

        def show
          prepare_show
          respond_to do |format|
            format.html
            format.xml
          end
        end

        private

        def prepare_show
          if !@type_class
            flash.now[:error] = "Unrecognised #{type_text}"
          elsif invalid_label?
            flash.now[:notice] = "Undefined #{type_text} with label <b> #{params[:label]} </b>. Did you mean #{link_to_alternative}?".html_safe
            @type_class = nil
          end

        end

        def find_ontology_type_class
          uri = params[:uri] || ontology_readers.first.default_parent_class_uri.to_s

          @type_class = ontology_readers.map do |ontology_reader|
            @type_class || ontology_reader.class_hierarchy.hash_by_uri[uri]
          end.compact.first

          @type_class ||= suggested_type_class.where(uri: uri).first
        end

        def find_and_authorize_assays
          @assays = []
          return unless @type_class
          @assays = Assay.authorize_asset_collection(Assay.where(assay_uri_field => possible_assay_uris), 'view')
        end

        def invalid_label?
          !params[:label].blank? && params[:label].downcase != @type_class.label.downcase
        end

        def link_to_alternative
          path = eval("#{controller_name}_path(:uri=>@type_class.uri, :label=> @type_class.label)")
          view_context.link_to(@type_class.label, path, style: 'font-style:italic;font-weight:bold;')
        end

        # the possible uris for assays based upon the selected @type_class uri and its children
        def possible_assay_uris
          if @type_class.is_suggested_type?
            ([@type_class] + @type_class.children).map(&:uri)
          else
            @type_class.hash_by_uri.keys | suggested_type_class.where(parent_uri: @type_class.uri.to_s).map(&:uri)
          end
        end

        ##### dynamic fields and attributes determined by the controller name #####

        def type_text
          controller_name.singularize.humanize.downcase
        end

        def assay_uri_field
          "#{controller_name.singularize}_uri".to_sym
        end

        def suggested_type_class
          "suggested_#{controller_name.singularize}".camelize.constantize
        end
      end
    end
  end
end
