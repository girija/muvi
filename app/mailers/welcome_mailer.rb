class WelcomeMailer < ActionMailer::Base
  default  :from =>  %{"muvi user" <info@muvi.com>},  :content_type => "text/html"

  def send_welcome_mail(user)
    @user = user
    mail(:to => user.email, :subject => "Welcome to Muvi #{user.display_name}!")
  end
end

