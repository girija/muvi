class Follow < ActiveRecord::Base

  extend ActsAsFollower::FollowerLib
  extend ActsAsFollower::FollowScopes

  # NOTE: Follows belong to the "followable" interface, and also to followers
  belongs_to :followable, :polymorphic => true
  belongs_to :follower,   :polymorphic => true

  def block!
    self.update_attribute(:blocked, true)
  end

  def self.user_followed_list(cur_user_id)
    user_list = Follow.select("followable_id").find(:all, :conditions => ["follower_id = #{cur_user_id} and followable_type = 'UserMovieList'"])

    select = "<select onchange='load_movies_for_this_list(this.value)' name='list_id' style='margin-left:20px; width:88%'>"
    select += "<option value='all'>All Lists</option>"
    unless user_list.blank?
      user_list.each do |ul|
        list = UserMovieList.find_by_id(ul.followable_id)
        unless list.blank?
	  select += "<option value='#{list.id}'>#{list.tag}</option>"
        end
      end
    end
    select += "</select>"
    return select.html_safe
    #return list_name.uniq!
  end

  def self.load_movies_from_lists(cur_user_id)
    user_list = Follow.select("followable_id").find(:all, :conditions => ["follower_id = #{cur_user_id} and followable_type = 'UserMovieList'"])
    movie_id = ""
    unless user_list.blank?
      user_list.each do |ul|
        list = UserMovieList.find_by_id(ul.followable_id)
        unless list.blank?
          m = ActiveSupport::JSON.decode(list.movie_id)
          unless movie_id.blank?
            movie_id = movie_id + m
          else
            movie_id = m
          end
        end
      end  
    end
    return movie_id.uniq!
  end

  def self.load_movies(cur_user_id, list_id)
    movie_id = ""
    list = UserMovieList.find_by_id(list_id)
    unless list.blank?
      m = ActiveSupport::JSON.decode(list.movie_id)
      unless movie_id.blank?
        movie_id = movie_id + m
      else
        movie_id = m
      end
    end
    return movie_id.uniq
  end

end

