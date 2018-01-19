# helper methods to support a wizard like form with multiple steps (e.g. for data file uploads)
module MultiStepWizardHelper

  def multi_step_back_buttons
    content_tag(:button,' ',class:'multi-step-start-button') +
      content_tag(:button,' ',class:'multi-step-back-button')
  end

  def multi_step_forward_buttons
    content_tag(:button,' ',class:'multi-step-next-button') +
      content_tag(:button,' ',class:'multi-step-end-button')
  end

end