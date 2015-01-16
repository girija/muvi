class Fan < ActiveRecord::Base
  belongs_to :celebrity
  belongs_to :user

  after_save :post_to_wall, :log_activity

  def log_activity
    star = Celebrity.find_by_id(self.celebrity_id)
    user = User.find(self.user_id)
    activity = Activity.new
    activity.user_id = self.user_id
    activity.secondary_subject_type = "Celebrity"
    activity.secondary_subject_id = self.celebrity_id
    if self.is_fan
      activity.subject_type = "Fan"
      activity.action = "#{user.display_name} is a fan of <a href='/stars/#{star.permalink}'>#{star.name}.</a>"
    elsif !self.is_fan
      activity.subject_type = "Unfan"
      activity.action = "#{user.display_name} left fandom of <a href='/stars/#{star.permalink}'>#{star.name}.</a>"
    end
    activity.save
  end


  def self.get_suggested_user(current_user)
    @suggested_user = []
    @suggested_connection = Fan.find(:all, :conditions => ["user_id = ?", current_user.id])
    unless @suggested_connection.blank?
      @suggested_connection.each do |s|
        @suggested = Fan.find(:first, :select => ["user_id, celebrity_id"], :conditions => ["celebrity_id = ? and user_id != ?", s.celebrity_id, current_user.id])
        unless @suggested.blank?
          @suggested_user << @suggested.user_id
        end
      end
    end
    return @suggested_user.uniq
  end

  def post_to_wall
    if self.user.user_profile &&  self.user.user_profile.post_to_social_media && self.user.facebook_omniauth
      begin
        client = Koala::Facebook::GraphAPI.new(self.user.facebook_token)
        begin
         client.delay.put_wall_post("",{:name => "#{self.user.display_name} became a fan of  #{self.celebrity.name}.",:link => "#{SITE_URL}/profile/#{self.user.id}/#{self.user.display_name}",:description => "Will you like to join #{self.celebrity.name}'s fandom?", :picture => "#{SITE_URL}/#{self.celebrity.image}"},profile_id="#{self.user.facebook_id}")
        rescue
        end
      rescue Koala::Facebook::OAuthException
          # getting this strange exception. (#506) Duplicate status message
          #TODO handle this exception
      end
    end
  end
  def self.check_user(user_id,celebrity_id)
    @want = Fan.find(:first, :conditions =>["user_id = ? AND celebrity_id = ? ", user_id, celebrity_id])
    return @want
  end

end
