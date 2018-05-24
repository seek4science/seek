module PasswordHelper
  # the password used for the Factories
  def generate_user_password
    '0' * User::MIN_PASSWORD_LENGTH
  end
end
