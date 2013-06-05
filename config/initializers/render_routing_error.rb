module ActionDispatch
  class ShowExceptions
    def render_exception(env, exception)
      if exception.kind_of? ActionController::RoutingError
        ErrorsController.action("error_404").call(env)
      else
        super
      end
    end
  end
end