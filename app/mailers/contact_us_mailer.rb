class ContactUsMailer < ActionMailer::Base
  default  :from =>  %{"muvi user" <info@muvi.com>},  :content_type => "text/html"

  def send_contact_us(object)
    @object = object
    mail(:to => 'info@muvi.com', :reply_to => @object.email, :subject => 'Message from muvi.com user')
  end
end

