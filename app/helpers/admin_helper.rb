module AdminHelper

  #true for tags with a name longer than 50chars or containing a semi-colon, comma, forward slash, colon or pipe character
  def dubious_tag?(tag)
    tag.text.length>50 || [";",",",":","/","|"].detect{|c| tag.text.include?(c)}
  end
  
  def admin_mail_to_links   
    result=""
    admins=Person.admins
    admins.each do |person|
      result << mail_to(h(person.email),h(person.name))
      result << ", " unless admins.last==person
    end
    return result.html_safe
  end
  
  #takes the terms and scores received from SearchStats, and generates a string
  def search_terms_summary terms_and_scores    
    return "<span class='none_text'>No search queries during this period</span>".html_safe if terms_and_scores.empty?
    words=terms_and_scores.collect{|ts| "#{h(ts[0])}(#{ts[1]})" }
    words.join(", ").html_safe
  end

  def delayed_job_status
    status = ""
    begin
      pids = [0,1].collect do |n|
        Daemons::PidFile.new("#{Rails.root}/tmp/pids","delayed_job.#{n.to_s}")
      end
      pids.each do |pid|
        if pid.running?
          status << "Running [Process ID: #{pid.pid}]"
        else
          status << "<span class='error_text'>Not running</span>"
        end
        status << "&nbsp;:&nbsp;" unless pid == pids.last
      end

    rescue Exception=>e
      status = "<span class='error_text'>Unable to determine current status - #{e.message}</span>"
    end
    status.html_safe
  end

end
