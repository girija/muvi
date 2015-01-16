class Activity < ActiveRecord::Base
  belongs_to :actor, :class_name => 'User'
  belongs_to :subject, :polymorphic => true
  belongs_to :secondary_subject, :polymorphic => true
  belongs_to :user

  scope :poster_24hr_activitis, where("date(created_at) = '#{Date.today}' and secondary_subject_type = 'Poster'")
  scope :video_24hr_activitis, where("date(created_at) = '#{Date.today}' and secondary_subject_type = 'Video'")
  scope :movie_24hr_activitis, where("date(created_at) = '#{Date.today}' and secondary_subject_type = 'Movie'")
  scope :celeb_24hr_activitis, where("date(created_at) = '#{Date.today}' and secondary_subject_type = 'Celebrity'")
  scope :news_24hr_activitis, where("date(created_at) = '#{Date.today}' and secondary_subject_type = 'News'")

  scope :poster_1week_activitis, where("created_at BETWEEN '#{Date.today.end_of_week - 6}' AND '#{Date.today.end_of_week + 1}' and secondary_subject_type = 'Poster'")
  scope :video_1week_activitis, where("created_at BETWEEN '#{Date.today.end_of_week - 6}' AND '#{Date.today.end_of_week + 1}' and secondary_subject_type = 'Video'")
  scope :movie_1week_activitis, where("created_at BETWEEN '#{Date.today.end_of_week - 6}' AND '#{Date.today.end_of_week + 1}' and secondary_subject_type = 'Movie'")
  scope :celeb_1week_activitis, where("created_at BETWEEN '#{Date.today.end_of_week - 6}' AND '#{Date.today.end_of_week + 1}' and secondary_subject_type = 'Celebrity'")
  scope :news_1week_activitis, where("created_at BETWEEN '#{Date.today.end_of_week - 6}' AND '#{Date.today.end_of_week + 1}' and secondary_subject_type = 'News'")

  scope :latest, order('created_at desc nulls last')
  scope :latest_updated, order('updated_at desc nulls last')
  scope :limit, lambda{|l| limit(limit) }
  scope :actor_ids, lambda{|ids| where("actor_id in (?)", ids) }

  validates_presence_of :action
  acts_as_commentable

  def self.log_activity(subject, secondary_subject, action, actor_id)
    activity = Activity.where('actor_id = ?', actor_id).last
    h = {:subject => subject,:secondary_subject => secondary_subject, :action => action}
    if activity.blank?
      self.create(h.merge!({:actor_id => actor_id}))
    else
      activity.update_attributes(h)
    end
  end


  def self.fb_log(subject, secondary_subject, action, user_id, actor_name, facebook_id)
    values = {:subject => subject,:secondary_subject => secondary_subject, :action => action, :user_id => user_id, :actor_name => actor_name, :facebook_id => facebook_id}
    count = Activity.where('user_id = ?', user_id).count
    if count.to_i == 4
      Activity.where('user_id = ?', user_id).last.update_attributes(values)
    else
      Activity.create(values)
    end
  end

  def self.create_log_for_each_friend(post, movie, action, facebook_id, facebook_name)
    FacebookFriend.where('facebook_id = ?', facebook_id).each do |friend|
      Activity.fb_log(post, movie, action, friend.user_id, facebook_name, facebook_id) unless Activity.where(:user_id => friend.user_id).where(:subject_id => post.id).first
    end
  end
  
 # def self.log_activity(subject_type,subject_id,secondary_subject_type,secondary_subject_id,action,actor_id,actor_name,user_id)
#    if action == "rating"
#        text = ""
#    elsif action == "follow"
#        text = ""
#    elsif action == "watch"
#        text = ""
#    elsif action == "comment"
#        text = ""
#    elsif action == "fan"
#        text = ""
#    elsif action == "unfan"
#        text = ""
#    elsif action == "unfollow"
#        text = ""
#    end
#    Activity.create(:subject_id => subject_id, :subject_type => subject_type, :secondary_subject_id => secondary_subject_id, :secondary_subject_type => secondary_subject_type, :action => action, :actor_id => actor_id, :actor_name => actor_name, :user_id => user_id)
 # end

  def self.friend_activities(user)
    self.latest_updated.where('user_id = ? and secondary_subject_type != ? and subject_type != ?', user.id, 'Follow', 'Comment').includes(:subject, :secondary_subject).limit(4)
  end

  def self.get_connections_activity(users, limit = 5)
     self.latest_updated.where('user_id in (?) and secondary_subject_type != ? and subject_type != ? and subject_type != ?', users, 'Follow', 'Comment', 'Top Ten') .includes(:subject, :secondary_subject).order('created_at DESC').limit(limit)
  end

  def self.your_connections(user)
    @registered_user = []
    connections = user.user_connection
    unless connections.blank?
      unless connections.connections.blank?
        conn =  ActiveSupport::JSON.decode(connections.connections)
        conn.each do |usr|
          user = UserProfile.find(:first,:conditions => ["user_id = ?",usr])
          unless user.blank?
              if UserToken.find_by_user_id(usr).blank?
                @user = User.find(usr)
              else
                @registered_user << usr
              end
           end
        end
      end
    end
    return @registered_user
  end

end

