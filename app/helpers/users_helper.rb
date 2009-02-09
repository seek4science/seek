module UsersHelper

  def admin_mail_to_links
    res=""
    admins=User.find(:all,:conditions=>{:is_admin=>true}, :include=>:person)
    admins.each do |u|
      
      res << mail_to(u.person.email,u.person.name)
      res << ", " unless admins.last==u
      
    end

    res
  end
end