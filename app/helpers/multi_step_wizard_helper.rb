# helper methods to support a wizard like form with multiple steps (e.g. for data file uploads)
module MultiStepWizardHelper
  def multi_step_back_icons
    content_tag(:button, ' ', class: 'multi-step-start-icon') +
      content_tag(:button, ' ', class: 'multi-step-back-icon')
  end

  def multi_step_forward_icons
    content_tag(:button, ' ', class: 'multi-step-next-icon') +
      content_tag(:button, ' ', class: 'multi-step-end-icon')
  end

  def multi_step_start_button
    content_tag(:button, 'Start', class: 'multi-step-start-button btn btn-default')
  end

  def multi_step_end_button
    content_tag(:button, 'End', class: 'multi-step-end-button btn btn-default')
  end

  def multi_step_back_button
    content_tag(:button, 'Back', class: 'multi-step-back-button btn btn-default')
  end

  def multi_step_forward_button
    content_tag(:button, 'Next', class: 'multi-step-next-button btn btn-primary')
  end

  def wizard_footer_tips
    star = content_tag(:span, class: 'required') { '*' }
    help = content_tag(:span, id: 'help_link') { help_link(:data_file_wizard, link_text: 'Wizard guide', include_icon: true) }
    content_tag :div, id: 'wizard-footer-tips' do
      ('Fields marked with a ' + star + ' are required, other fields are optional ' + help).html_safe
    end
  end
end
