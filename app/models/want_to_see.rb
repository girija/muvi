class WantToSee < ActiveRecord::Base
  belongs_to :movie
  belongs_to :user

  after_save :post_to_wall, :log_activity
  def log_activity
    movie = Movie.find_by_id(self.movie_id)
    user = User.find(self.user_id)
    activity = Activity.new
    activity.user_id = self.user_id
    activity.secondary_subject_type = "Movie"
    activity.secondary_subject_id = self.movie_id
    if self.is_want_to_see
      activity.subject_type = "Watch"
      activity.action = "#{user.display_name} wants to watch <a href='/movies/#{movie.permalink}'>#{movie.name}'>#{movie.name}.</a>"
    else
      activity.subject_type = "Not watch"
      activity.action = "#{user.display_name} don't wants to watch <a href='/movies/#{movie.permalink}'>#{movie.name}'>#{movie.name}.</a>"
    end
    activity.save
  end

  def post_to_wall
    if self.user.user_profile &&  self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(self.user.facebook_token)
        begin
         client.delay.put_wall_post("",{:name => "#{self.user.display_name} wants to see #{self.movie.name}.",:link => "#{SITE_URL}/profile/#{self.user.id}/#{self.user.display_name}",:description => "What do you think is it a cool idea?", :picture => "#{SITE_URL}/#{self.movie.banner_image}"},profile_id="#{self.user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end

  def self.fm_want_to_see(label, user_id)
    movie_watch = ""
    want_to_see = WantToSee.where("user_id=#{user_id}").find(:all, :limit => [2])
    unless want_to_see.blank?
      want_to_see.each do |w|
        mov = Movie.find_by_id(w.movie_id)
        if movie_watch.blank?
          movie_watch = label + " <a href='/movies/#{mov.permalink}'>#{mov.name}</a>"
        else
          movie_watch += ", <a href='/movies/#{mov.permalink}'>#{mov.name}</a>".html_safe
        end
      end
    end
    return movie_watch.html_safe
  end

  def self.fm_fan(label, user_id)
    celeb_fan = ""
    fan = Fan.where("user_id=#{user_id}").find(:all, :limit => [2])
    unless fan.blank?
      fan.each do |w|
        celeb = Celebrity.find_by_id(w.celebrity_id)
        if celeb_fan.blank?
          celeb_fan = label + " <a href='/celebrities/#{celeb.permalink}'>#{celeb.name}</a>"
        else
          celeb_fan += ", <a href='/celebrities/#{celeb.permalink}'>#{celeb.name}</a>"
        end
      end
    end
    return celeb_fan.html_safe
  end

  def self.check_user(user_id,movie_id)
    @want = WantToSee.find(:first, :conditions =>["user_id = ? AND movie_id = ? ", user_id, movie_id])
    return @want
  end

end

