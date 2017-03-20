module RunsHelper
  def runs_table(runs, redirect_to = nil)
    runs.map do |run|
      workflow = run.workflow
      version = run.workflow_version
      workflow_version = workflow.find_version(version)
      created_at = "#{time_ago_in_words(run.created_at)} ago"

      if run.is_a?(Sweep) # If a sweep, get the latest finish time of its runs
        if run.runs.any? { |r| r.finish_time.blank? }
          finish_time = 0
          finish_time_text = '-'
        else
          max_time = run.runs.map(&:finish_time).max
          finish_time = max_time.to_i
          finish_time_text = "#{time_ago_in_words(max_time)} ago"
        end
      else
        if run.finish_time.blank?
          finish_time = 0
          finish_time_text = '-'
        else
          finish_time = run.finish_time.to_i
          finish_time_text = "#{time_ago_in_words(run.finish_time)} ago"
        end
      end

      [link_to("#{image(run.is_a?(Sweep) ? 'sweep_run' : 'simple_run')}#{run.name}".html_safe,
               run.is_a?(Sweep) ? main_app.sweep_path(run) : taverna_player.run_path(run),
               class: 'with_icon'
              ),
       run.contributor.display_name,
       workflow.can_view? ? link_to(workflow_version.title, main_app.workflow_path(workflow, version: version)) : workflow_version.title,
       workflow.category.name,
       "#{run.state.capitalize} #{(run.complete? ? '' : image_tag('ajax-loader.gif', style: 'vertical-align: middle'))}".html_safe,
       created_at,
       run.created_at.to_i,
       finish_time_text,
       finish_time,
       delete_or_cancel_button(run, redirect_to)]
    end
  end

  def delete_or_cancel_button(run, redirect_to)
    if run.can_delete?
      if run.complete?
        # Delete
        unless current_user.guest?
          content_tag(:li) do
            link_to run.is_a?(Sweep) ? main_app.sweep_path(run, redirect_to: redirect_to) :
                                       taverna_player.run_path(run, redirect_to: redirect_to),
                    method: :delete, data: { confirm: 'Are you sure?' } do
              content_tag(:span, class: 'icon') do
                image('destroy') + ' Delete'
              end
            end
          end
        end
      else
        # Cancel
        content_tag(:li) do
          link_to run.is_a?(Sweep) ? main_app.cancel_sweep_path(run) :
                                     taverna_player.cancel_run_path(run),
                  method: :put, data: { confirm: 'Are you sure?' } do
            content_tag(:span, class: 'icon') do
              image('destroy') + ' Cancel'
            end
          end
        end
      end
    end
  end
end
