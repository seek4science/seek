class MailerPreview < ActionMailer::Preview
  def project_creation_request_auto_accepted
    Mailer.notify_admins_project_creation_accepted(nil, Person.last, Project.first)
  end

  def project_creation_request_accepted
    Mailer.notify_admins_project_creation_accepted(Person.first, Person.last, Project.first)
  end
end
