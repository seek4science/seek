module RunsHelper

  def runs_table(runs)
    runs.map do |run|
      workflow = run.workflow
      created_at = run.created_at.strftime("%e %b %Y %H:%M:%S %Z")

      if run.is_a?(Sweep)
        finish_time = run.runs.any? {|r| r.finish_time.blank? } ? '' : run.runs.map { |r| r.finish_time }.max.strftime("%e %b %Y %H:%M:%S %Z")
      else
        finish_time = run.finish_time.blank? ? '' : run.finish_time.strftime("%e %b %Y %H:%M:%S %Z")
      end

      action_buttons = render(:partial => "taverna_player/runs/delete_or_cancel_button", :locals => { :run => run })
      [link_to(run.name, run.is_a?(Sweep) ? main_app.sweep_path(run) : taverna_player.run_path(run)),
       link_to(workflow.title, main_app.workflow_path(workflow)),#, :version => run.workflow_version)),
       workflow.category.name,
       run.is_a?(Sweep) ? 'Sweep' : 'Simple',
       "#{run.state} #{(run.complete? ? '' : image_tag('ajax-loader.gif', :style => "vertical-align: middle"))}".html_safe,
       created_at,
       finish_time,
       action_buttons]
    end
  end

end