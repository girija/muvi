class PostCardMailer < ActionMailer::Base
  default  :from =>  %{"muvi user" <info@muvi.com>},  :content_type => "text/html"

  def send_post_card(object)
    @object = object
    mail(:to => 'cards@muvi.com', :reply_to => 'info@muvi.com', :subject => 'New post card request from muvi.com user')
  end

end
