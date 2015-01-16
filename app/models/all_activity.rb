class AllActivity < ActiveRecord::Base
  belongs_to  :user
  belongs_to :target_user,:foreign_key => "target_user_id", :class_name => 'User'

  after_save :add_to_notification

  def add_to_notification
    @act = AllActivity.find(self.id)
    if @act.activity_type == "asked" or @act.activity_type == "thanked" or @act.activity_type == "has recommended" or @act.activity_type == "has not recommended"
      notification_id = AllActivityHelper.add_notification(1, @act.target_user_id, @act)
    elsif @act.activity_type == "kudos"
      AllActivity.add_give_kudos(@act)
    elsif @act.activity_type == "list_rated_movie"
      AllActivity.add_follow_rating(@act)
    elsif @act.activity_type == "follow filmography" or @act.activity_type == "invited"
      AllActivity.delay.add_follow_filmography(@act)

    elsif @act.activity_type == "follow"
      AllActivity.delay.add_follow_list(@act)
      AllActivityHelper.add_list_notification(1, @act.user_id, @act, '')

    elsif @act.activity_type == "want to see"
      AllActivity.delay.check_and_add_want_to_see(@act)
      AllActivity.add_follow_new_list(@act)

    elsif @act.activity_type == "released movie" or @act.activity_type == "follow celeb filmography" or @act.activity_type == "follow this list"
      AllActivity.add_admin_notification(@act)

    #point no 16 in google doc
    #elsif @act.activity_type == "want to see" or @act.activity_type == "saw"
    elsif @act.activity_type == "saw"
      AllActivity.add_follow_new_list(@act)

    elsif @act.activity_type == "new movie added"
      AllActivity.add_filmography_notification(@act)     
    else
      notification_id = AllActivityHelper.add_notification(1, @act.user_id, @act)
    end

  end


  def self.add_filmography_notification(act)
    a = ActiveSupport::JSON.decode(act.activity)
    celeb_follow = Follow.find(:all, :conditions => ["followable_id = #{a[0]["target"]["id"]} and followable_type = 'Celebrity'"])
    unless celeb_follow.blank?
      celeb_follow.each do |cf|
        AllActivityHelper.add_list_notification(1, cf.follower_id, act, '') 
      end
    end
  end
  
  def self.add_follow_new_list(act)
    @ul = UserMovieList.find(:all, :conditions => ["tag IS NOT NULL"])  
    unless @ul.blank?
      @ul.each do |ul|
        movie_id_pos = ul.movie_id.scan(/\b(#{act.movie_id})\b/) 
        unless movie_id_pos.blank?
          user = User.find_by_id(act.user_id)
          if !ul.followed_by?(user)
            notification_id = AllActivityHelper.add_list_notification(1, act.user_id, act, ul.id)
          end
        end
      end
    end
  end

  def self.add_follow_rating(act)
    notification_id = AllActivityHelper.add_notification(1, act.target_user_id, act)
  end

  def self.add_give_kudos(act)
    notification_id = AllActivityHelper.add_notification(1, act.target_user_id, act)
  end

  def self.check_and_add_want_to_see(act)
    #act = AllActivity.find_by_id(5179)

    # when an user want to see a movie, then check if there is any user who saw it. if yes, then sent notification to ask for recommendation
    user_saw_the_movie = 0
    user = User.find(:all)
    unless user.blank?
      user.each do |u|
        @seen_id = AllActivity.get_current_user_seen_list(u.id)
        if @seen_id.include?("#{act.movie_id.to_s}")
          if user_saw_the_movie != 0
            break
          else
            user_saw_the_movie = u.id
          end
        end
      end

      if user_saw_the_movie != 0
        notification_id = AllActivityHelper.add_notification(1, user_saw_the_movie, act)
      end
    end
  end

  def self.add_admin_notification(act)
    u = User.where(last_sign_in_at: 30.days.ago..0.days.from_now).find(:all, :conditions => ["sign_in_count > 0"])
    unless u.blank?
      u.each do |c|
        conn = c.id
        notification_id = AllActivityHelper.add_admin_notification(1, conn, act)
      end
    end
  end

  def self.add_follow_filmography(act)
    u = User.where(last_sign_in_at: 30.days.ago..0.days.from_now).find(:all, :conditions => ["id != #{act.user_id} and sign_in_count > 0"])
    unless u.blank?
      u.each do |c|
        conn = c.id
        notification_id = AllActivityHelper.add_notification(1, conn, act)
      end
    end
  end


  def self.add_follow_list(act)
    u = User.where(last_sign_in_at: 30.days.ago..0.days.from_now).find(:all, :conditions => ["sign_in_count > 0"])
    #u = User.find(:all, :conditions => ["id = #{act.user_id}"])
    unless u.blank?
      u.each do |c|
        conn = c.id
        notification_id = AllActivityHelper.add_notification(1, conn, act)
      end
    end
  end

  def self.create_notification_manually(act_type)
    act = AllActivity.find(:all, :conditions => ["activity_type = '#{act_type}' and notification_added = 'f'"])
    unless act.blank?
      act.each do |a|
        puts "**************"
        puts a.user_id
        notification_id = AllActivityHelper.add_notification(1, a.user_id, a)
        puts notification_id
        puts "++++++++++++++"
      end
    end
  end

  def self.create_next_movie_notification(cur_user, celeb_id)
    @final_arr = []
    actor = ""
    verb = ""
    object = ""
    target = ""
    movie_id = ""

    wanna_see_movies = AllActivity.get_current_user_wanna_list_movies(cur_user.id)
    celeb = Celebrity.find_by_id(celeb_id)
    next_movie_arr = (Celebrity.upcoming_movies(celeb) - wanna_see_movies)#.first
    next_movie = next_movie_arr[rand(next_movie_arr.count)]
    unless next_movie.blank?
      image = ""
      image = POSTER_URL + next_movie.banner_image
      movie_id = next_movie.id
      object = {:url => "/movies/#{next_movie.permalink}", :objectType => "list", :id => "#{next_movie.id}",
        :image => {:url => "#{image}", :width => 250, :height => 250},
        :displayName => "#{next_movie.name}"
      }
      unless cur_user.user_profile.profile_image_file_name.blank?
          image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless cur_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

      verb = "next movie"
      up = cur_user.user_profile
      actor = {:url => "http://www.muvi.com/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{cur_user.display_name}"
           }
      target = { :url => "/stars/#{celeb.permalink}",
                :objectType => "star",
                :id => "#{celeb.id}",
                :image => {:url => "", :width => 250, :height => 250},
                :displayName => "#{celeb.name}"
              }

      @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
      act = AllActivity.new
      act.user_id = cur_user.id
      act.movie_id = movie_id
      act.activity = @final_arr.to_json
      act.activity_type = "next movie"
      act.save
    end
  end


  def self.create_follow_activity(list, cur_user, type)
    @final_arr = []
    actor = ""
    verb = ""
    object = ""
    target = ""

    unless cur_user.user_profile.profile_image_file_name.blank?
        image_url = "/system/profile_images/#{cur_user.user_profile.id}/small/#{cur_user.user_profile.profile_image_file_name.gsub(' ', '%20')}"
      else
        unless cur_user.facebook_id.blank?
          image_url = "http://graph.facebook.com/#{cur_user.facebook_id}/picture?type=normal"
        else
          image_url = "/images/no-profile.png"
        end
      end

    up = cur_user.user_profile

    #actor = {:url => "http://www.muvi.com/profile/#{cur_user.id}/#{User.convert_to_seo_url(cur_user.display_name)}",
    actor = {:url => "http://www.muvi.com/#{up.permalink}",
              :objectType => "user",
              :id => "#{cur_user.id}",
              :image => {:url => "#{image_url}", :width => 250, :height => 250},
              :displayName => "#{cur_user.display_name}"
           }

    if type == ""
      verb = "followed"
    else
      verb = "followed filmography"
    end

    if type.blank?
      object = {:url => "#", :objectType => "list", :id => "#{list.id}",
               :image => {:url => "", :width => 250, :height => 250},
               :displayName => "#{list.tag}"
              }
    else
      object = {:url => "#", :objectType => "celebrity", :id => "#{list.id}",
               :image => {:url => "", :width => 250, :height => 250},
               :displayName => "#{list.name}"
              }
    end

    @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
    act = AllActivity.new
    act.user_id = cur_user.id
    act.activity = @final_arr.to_json
    if type == ""
      act.activity_type = "follow"
    else
      act.activity_type = "follow filmography"
    end
    act.save
  end

  def self.get_current_user_wanna_list_movies(cur_user_id)
    movs = []
    cur_user = ListOfMovie.find(:all, :conditions => ["user_id IN (#{cur_user_id})"])
    unless cur_user.blank?
      cur_user.each do |c|
        unless c.wanna_see_lists.blank?
          list = ActiveSupport::JSON.decode(c.wanna_see_lists)
          unless list.blank?
            list.each do |l|
              unless l.blank?
                if l["target"] == "wanna see"
                  movs << Movie.find_by_id(l["object"]["id"].to_s)
                end
              end
            end
          end
        end
      end
    end
    return movs
  end


  def self.get_current_user_wanna_list(cur_user_id)
    mov_id = []
    cur_user = ListOfMovie.find(:all, :conditions => ["user_id IN (#{cur_user_id})"]) 
    unless cur_user.blank?
      cur_user.each do |c|
        unless c.wanna_see_lists.blank?
          list = ActiveSupport::JSON.decode(c.wanna_see_lists)
          unless list.blank?
            list.each do |l|
              unless l.blank?
                if l["target"] == "wanna see"
       	          mov_id << l["object"]["id"].to_s
                end
              end
            end
          end
        end
      end
    end
    return mov_id
  end



  def self.get_current_user_seen_list(cur_user_id)
    mov_id = []
    cur_user = ListOfMovie.find(:all, :conditions => ["user_id IN (#{cur_user_id})"])
    unless cur_user.blank?
      cur_user.each do |c|
        unless c.seen_lists.blank?
          list = ActiveSupport::JSON.decode(c.seen_lists)
          unless list.blank?
            list.each do |l|
              unless l.blank?
                if l["target"] == "seen it"
                  mov_id << l["object"]["id"].to_s
                end
              end
            end
          end
        end
      end
    end
    return mov_id
  end


  
  def self.check_for_wanna_notification(cur_user_id)
    m_id = AllActivity.get_current_user_wanna_list(cur_user_id)
    @all_wanna_see_activity = AllActivityHelper.get_wanna_list(1,cur_user_id, m_id)
    unless @all_wanna_see_activity.blank?
      @all_wanna_see_activity.each do |a|
       ApplicationHelper.broadcast("/home/index/#{cur_user_id}", a)
      end
    end
  end

  def self.check_for_seen_notification(cur_user_id)
    seen_m_id = AllActivity.get_current_user_seen_list(cur_user_id)
    @all_seen_activity = AllActivityHelper.get_seen_list(1,cur_user_id, seen_m_id)
    unless @all_seen_activity.blank?
      @all_seen_activity.each do |a|
        ApplicationHelper.broadcast("/home/index/#{cur_user_id}", a)
      end
    end
  end

  def self.create_movie_added_json(movie_id, celeb_id)
    @final_arr = []
    actor = ""
    verb = ""
    object = ""
    target = ""
    actor = {:url => "",
              :objectType => "user",
              :id => "",
              :image => {:url => "#", :width => 250, :height => 250},
              :displayName => ""
           }
    verb = "movie added for a celebrity"

    m = Movie.find_by_id(movie_id)
    url = ""
    image = ""
    mname = ""
    unless m.blank?
      url = "http://www.muvi.com/movies/#{m.permalink}"
      image = POSTER_URL + m.banner_image
      mname = m.name
    end
    object = {:url => "#{url}", :objectType => "movie", :id => "#{movie_id}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{mname}"
              }

    c = Celebrity.find_by_id(celeb_id)
    url = ""
    image = ""
    cname = ""
    unless c.blank?
      url = "http://www.muvi.com/stars/#{c.permalink}"
      cname = c.name      
    end
    target = {:url => "#{url}", :objectType => "movie", :id => "#{celeb_id}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{cname}"
              }
    @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
    return @final_arr.to_json

  end

  def self.create_json(l)
    @final_arr = []
    actor = ""
    verb = ""
    object = ""
    target = ""


    u = User.find_by_id(l["actor"]["id"])
    up = u.user_profile
    actor = {:url => "http://www.muvi.com/#{up.permalink}",
              :objectType => "user",
              :id => "#{l["actor"]["id"]}",
              :image => {:url => "#", :width => 250, :height => 250},
              :displayName => "#{l["actor"]["displayName"]}"
           }

    verb = l["target"]

    m = Movie.find_by_id(l["object"]["id"])
    url = ""
    image = ""
    unless m.blank?
      url = "http://www.muvi.com/movies/#{m.permalink}"
      image = POSTER_URL + m.banner_image
    end
    object = {:url => "#{url}", :objectType => "movie", :id => "#{l["object"]["id"]}",
               :image => {:url => "#{image}", :width => 250, :height => 250},
               :displayName => "#{l["object"]["displayName"]}"
              }

    @final_arr << {:published => Date.today, :actor => actor, :verb => verb, :object => object, :target => target}
    return @final_arr.to_json
  end


end
