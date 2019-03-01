class Identity < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :omniauthable, :omniauth_providers => [:elixir_aai]
  devise :timeoutable, :timeout_in => 10.seconds
  #  :database_authenticatable, :registerable,
  #  :recoverable, :rememberable, :validatable

  belongs_to :user

  cattr_accessor :current_identity

  def self.from_omniauth(auth)

    require 'securerandom' #to set the seek user password to something random when the user is created

    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?
    identity = Identity.where(:provider => auth.provider, :uid => auth.uid).first

    if !identity
      identity = Identity.new(provider: auth.provider,
                              uid: auth.uid,
                              email: auth.info.email
            )
      identity.save!
    end

    Identity.current_identity = identity

    # # TODO: Extra logic to cope with other possibilities
    #   person = Person.where(:email => auth['info']['email']).first
    #   if person
    #     user = person.user
    #     if !user
    #       user = User.new(login: auth.info.nickname,
    #                       provider: auth.provider,
    #                       uid: auth.uid
    #          )
    #       user.password = SecureRandom.hex
    #       user.password_confirmation = user.password
    #
    #       user.activate
    #       person.user = user
    #       person.save!
    #     end
    #   end
    # end
    # `auth.info` fields: email, first_name, gender, image, last_name, name, nickname, phone, urls
    # if user
    #   if user.provider.nil? and user.uid.nil?
    #     user.uid = auth.uid
    #     user.provider = auth.provider
    #     user.save
    #   end
    # # else
    #   user = User.new(provider: auth.provider,
    #                   uid: auth.uid,
    #                   email: auth.info.email,
    #                   name: "#{auth.info.first_name} #{auth.info.last_name}"
    #   )
    #   user.skip_confirmation!
 #   end

    identity
  end


end


