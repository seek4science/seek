module RunsHelper

  def runs_table(runs, redirect_to=nil)
    runs.map do |run|
      workflow = run.workflow
      created_at = "#{time_ago_in_words(run.created_at)} ago"

      if run.is_a?(Sweep) # If a sweep, get the latest finish time of its runs
        finish_time = run.runs.any? {|r| r.finish_time.blank? } ? '' :
            "#{time_ago_in_words(run.runs.map { |r| r.finish_time }.max)} ago"
      else
        finish_time = run.finish_time.blank? ? '' : "#{time_ago_in_words(run.finish_time)} ago".html_safe
      end

      action_buttons = render(:partial => "taverna_player/runs/delete_or_cancel_button", :locals => { :run => run, :redirect_to => redirect_to })
      [link_to("#{image(run.is_a?(Sweep) ? 'sweep_run' : 'simple_run')}#{run.name}".html_safe,
               run.is_a?(Sweep) ? main_app.sweep_path(run) : taverna_player.run_path(run),
               :class => 'with_icon'
       ),
       workflow.can_view? ? link_to(workflow.title, main_app.workflow_path(workflow)) : workflow.title,
       workflow.category.name,
       "#{run.state} #{(run.complete? ? '' : image_tag('ajax-loader.gif', :style => "vertical-align: middle"))}".html_safe,
       created_at,
       finish_time,
       action_buttons]
    end
  end

  def mime_type_options(original)
    types = [["text/plain", "text/plain"], ["text/csv", "text/csv"]]
    types.prepend([original, original]) unless types.any? { |a| a[0] == original }
    options_for_select([[p.metadata[:type], p.metadata[:type]], ["text/csv", "text/csv"]])
  end

end