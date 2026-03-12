module Ga4gh
  module Trs
    module V2
      class ToolsController < TrsBaseController
        before_action :paginate_and_filter, only: [:index]
        before_action :get_tool, only: [:show]

        def show
          respond_with(@tool, adapter: :attributes, root: '')
        end

        def index
          respond_with(@tools, adapter: :attributes, root: '')
        end

        private

        def controller_model
          Workflow
        end

        def paginate_and_filter
          @offset = tools_index_params[:offset]&.to_i
          @limit = tools_index_params[:limit]&.to_i || 1000

          # Filtering
          workflows = relationify_collection(Workflow.authorized_for('view'))
          workflows = workflows.includes(:projects, :creators, :workflow_class, :git_versions, :standard_versions)
          workflows = workflows.where(id: tools_index_params[:id]) if tools_index_params[:id].present?
          workflows = workflows.where('LOWER(workflows.title) LIKE ?', "%#{tools_index_params[:name].downcase}%") if tools_index_params[:name].present?
          workflows = workflows.where('LOWER(workflows.description) LIKE ?', "%#{tools_index_params[:description].downcase}%") if tools_index_params[:description].present?
          workflows = workflows.none if tools_index_params[:toolClass].present? && tools_index_params[:toolClass] != ToolClass::WORKFLOW.name
          if tools_index_params[:descriptorType].present?
            class_key = ToolVersion::DESCRIPTOR_TYPE_MAPPING.invert[tools_index_params[:descriptorType].upcase]
            if class_key
              workflows = workflows.where(workflow_classes: { key: class_key })
            else
              workflows = workflows.none
            end
          end
          workflows = workflows.where(projects: { title: tools_index_params[:organization] }) if tools_index_params[:organization].present?
          workflows = workflows.none if tools_index_params[:checker].present? && tools_index_params[:checker].to_s.downcase != 'false'
          if tools_index_params[:author].present?
            people = Person.all.select { |p| p.name == tools_index_params[:author] }.map(&:id)
            workflows = workflows.where(people: { id: people }).or(workflows.where('workflows.other_creators LIKE ?', "%#{tools_index_params[:author]}%"))
          end
          # Not implemented:
#          tools_index_params[:alias]
#          tools_index_params[:registry]
#          tools_index_params[:toolname]

          workflows = workflows.offset(@offset) if @offset
          count = workflows.count
          workflows = workflows.limit(@limit)

          offset = @offset || 0
          last_page_offset = count - @limit
          last_page_offset = nil if last_page_offset <= 0
          response.headers['next_page'] = ga4gh_trs_v2_tools_url(tools_index_params.merge(offset: offset + @limit)) if count > @limit
          response.headers['last_page'] = ga4gh_trs_v2_tools_url(tools_index_params.merge(offset: last_page_offset))
          response.headers['current_offset'] = @offset if @offset
          response.headers['current_limit'] = @limit
          response.headers['self_link'] = request.url

          @tools = workflows.map { |workflow| Tool.new(workflow) }
        end

        def tools_index_params
          params.permit(%i[id alias toolClass descriptorType registry organization name toolname description author checker offset limit])
        end
      end
    end
  end
end
