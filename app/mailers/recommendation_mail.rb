class RecommendationMail < ActionMailer::Base
  default  :from =>  %{"muvi user" <info@muvi.com>}, :reply_to => 'infon@muvi.com', :content_type => "text/html"

  def send_recommendation(email_ids, subj, content)
    @content = content
    mail(:to => email_ids, :subject => subj)
  end
end

