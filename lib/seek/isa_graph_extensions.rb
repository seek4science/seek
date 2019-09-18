module Seek
  module IsaGraphExtensions
    include ISAHelper

    def isa_children
      root_item = controller_model.find(params[:id])

      @hash = Seek::IsaGraphGenerator.new(root_item).generate(depth: 1, include_self: false, parent_depth: 0)

      respond_to do |format|
        format.json { render 'general/isa_children' }
      end
    end
  end
end
