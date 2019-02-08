class CallbacksController < Devise::OmniauthCallbacksController

  def elixir_aai
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.new_record?
      @user.save
      sign_in @user
      flash[:notice] = "#{I18n.t('devise.registrations.signed_up')} Please ensure your profile is correct."
      redirect_to edit_user_path(@user)
    else
      sign_in_and_redirect @user
    end
  end

end