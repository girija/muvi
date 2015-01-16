class UserMailer < ActionMailer::Base
  require 'mandrill'
  #default  :from =>  %{"muvi user" <info@muvi.com>}, :reply_to => 'no-reply@muvi.com', :content_type => "text/html"
  default  :from =>  %{"Muvi" <info@muvi.com>}, :content_type => "text/html"

  def send_email_invitation(email_ids, subj, content)
    mail(:to => email_ids, :subject => subj, :body => content)
  end

    
  def notify(email_id, subj, content)
   puts "ready to send" 
   mail(:to => email_id, :subject => subj, :body => content)
   puts "sent"
  end

  def forgot_password(user,pwd_link)
    @user_name = user.display_name
    subject = "Don't worry new password to Muvi here."
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    template_name = "forgot password"
    login_link = "<a href='#{pwd_link}' style='color:#fff;text-decoration:none;'>Login</a>"
    template_content = [{"name"=>"user_name", "content"=>@user_name},{"name"=>"login_link","content"=>login_link}]
    message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
    result = mandrill.messages.send_template template_name, template_content, message#, async, ip_pool, send_at
  end

  def welcome(user)
    @user_name = user.user_profile.nil? ? "" : user.user_profile.display_name
    subject = "Lets Discover Movies :)"
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    template_name = "welcome"
    login_url = "http://www.muvi.com/users/sign_in?authentication_key=#{user.authentication_token}"
    login_link = "<a href='#{login_url}' style='color:#fff;text-decoration:none;'>Login</a>"
    template_content = [{"name"=>"user_name", "content"=>@user_name},{"name"=>"login_link","content"=>login_link}]
    message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
    result = mandrill.messages.send_template template_name, template_content, message
  end

  def send_payment_confirmation(user)
    subject = "Subscription successful !"
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    template_name = "payment"
    template_content = [{"name"=>"user_name", "content"=>user.display_name}]
    message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
    result = mandrill.messages.send_template template_name, template_content, message
  end

end
