module MailerHelper
  def self.fetch_top_send_mail
    AllActivity.find(:all,:conditions=>["created_at > ? ",2.hours.ago]).each do |activity|
      linked_user_activity = ""
      activity_obj = JSON.parse(activity.activity)
      obj_type = activity_obj[0].nil? ? activity_obj["object"]["objectType"] : activity_obj[0]["object"]["objectType"]
      obj_id = activity_obj[0].nil? ? activity_obj["object"]["id"] : activity_obj[0]["object"]["id"]
      if activity.activity_type == "has recommended" or activity.activity_type == "has not recommended" or activity.activity_type == "thanked" or activity.activity_type == "asked"
        target_user = User.find_by_id(activity.target_user_id)
        if target_user.subscribe_notification #&& (activity.target_user_id == 50174 or activity.target_user_id == 1420)
          notification = AllNotification.find_by_activity_id(activity.id)
	  notif_id = notification.blank? ? 0 : notification.id
          NotifyMailer.notify_movie(activity.target_user_id,obj_id,activity.user_id,activity.activity_type,notif_id)
        end
      else
        @linked_users = activity.user_id.blank? ? [] : MailerHelper.linked_users(activity.user_id)
        @linked_users.each do |l_user|
          linked_user = User.find_by_id(l_user)
          if obj_type == 'movie'
            linked_user_activity = AllActivity.where("movie_id = #{obj_id} and user_id = #{l_user}")
          elsif obj_type == 'celeb'
            linked_user_activity = Follow.where("followable_id = #{obj_id} and followable_type = 'Celebrity' and follower_id = #{l_user} and follower_type = 'User'")
          elsif obj_type == 'list'
            linked_user_activity = Follow.where("followable_id = #{obj_id} and followable_type = 'UserMovieList' and follower_id = #{l_user} and follower_type = 'User'")
          end
          log = EmailNotifLog.where("user_id = #{l_user} and related_user_id = #{activity.user_id} and date(created_at) = '#{Date.today}'")
          if log.blank?
            EmailNotifLog.create(:user_id => l_user ,:related_user_id=> activity.user_id ,:object_id => obj_id, :object_type => obj_type)
            if obj_type == 'movie' && linked_user.subscribe_notification
              if linked_user_activity.blank?
                NotifyMailer.notify_movie(l_user,obj_id,activity.user_id)
              else
                wanna_see = AllActivity.where("movie_id = #{obj_id} and user_id = #{l_user} and activity_type = 'want to see'")
                seen = AllActivity.where("movie_id = #{obj_id} and user_id = #{l_user} and activity_type = 'saw'")
                if !wanna_see.blank? && activity.activity_type == "saw" && activity.user_id != l_user
                  notification = AllNotification.find_by_activity_id(activity.id)
                  NotifyMailer.notify_movie(l_user,obj_id,activity.user_id,'want to see',notification.id)
                end
  
                if activity.activity_type == "want to see" && !seen.blank? && activity.user_id != l_user
                  NotifyMailer.notify_movie(activity.user_id,obj_id,l_user,'want to see',0)
                end
              end
            elsif obj_type == 'celeb' && linked_user_activity.blank?  && linked_user.subscribe_notification
              NotifyMailer.notify_celebrity(l_user,obj_id,activity.user_id)
            elsif obj_type == 'list' && linked_user_activity.blank?  && linked_user.subscribe_notification
              NotifyMailer.notify_list(l_user,obj_id,activity.user_id)  
            end
          end
        end
      end
    end
  end


  def self.extract_topobjects(days)
    @top_lists = Follow.select("followable_id,count(*) as cnt").where(:followable_type => "UserMovieList",:created_at => (Date.today - (days-1))..(Date.today+1)).group("followable_id").order("cnt desc").limit(5)
    @top_celebs = Follow.select("followable_id,count(*) as cnt").where(:followable_type => "Celebrity",:created_at => (Date.today - (days-1))..(Date.today+1)).group("followable_id").order("cnt desc").limit(5)
    @top_movies = []
    s_w_movies = []
    list_movies = []
    seen_wanna_see_movies = AllActivity.select("movie_id,count(*) as cnt").where("activity_type IN ('want to see','saw') and created_at BETWEEN '#{(Date.today - (days-1))}' AND '#{(Date.today+1)}'").group("movie_id").order("cnt desc").limit(5)
    seen_wanna_see_movies.each do |swm|
      s_w_movies << swm.movie_id
    end
    @movie_list = UserMovieList.where(:updated_at => (Date.today - (days-1))..(Date.today+1))
    @movie_list.each do |list|
      begin
        all_movie = ActiveSupport::JSON.decode(list.tag_list)
        all_movie.each do |movie|
          if movie["published"].to_date >= (Date.today - (days-1))
            list_movies << movie["object"]["id"]
          end
        end
      rescue
      end
    end
    p(s_w_movies)
    list_added_movie = list_movies.uniq[0..4]
    @top_movies = s_w_movies + list_added_movie
  end

  def self.linked_users(user_id)
    related_followers = []
    all_seen_list = ListOfMovie.where("user_id = #{user_id}")
    all_seen_list.each do |a_lst|
      a_lst.followers.each do |alf|
        related_followers << alf.id
      end
    end
    all_list = UserMovieList.where("user_id = #{user_id} and tag != ''")
    all_list.each do |lst|
      lst.followers.each do |lf|
        related_followers << lf.id
      end
    end
    @linked_users = related_followers.uniq
  end
  
  def self.extract_object_activities
    MailerHelper.extract_topobjects(1)
    days = 1
    @top_movies.each do |t_movie|
      activities = AllActivity.select("user_id").where("movie_id = #{t_movie.to_i} and created_at BETWEEN '#{(Date.today - (days-1))}' AND '#{(Date.today+1)}'")
      movie_activities = []
      activities.each do |act|
        movie_activities << act.user_id
      end
      mov_activs = movie_activities.uniq
      mov_activs.each do |mov_user_id|
        MailerHelper.linked_users(mov_user_id)
        @linked_users.each do |l_user|
          linked_user = User.find_by_id(l_user)
          linked_user_activity = AllActivity.where("movie_id = #{t_movie.to_i} and user_id = #{l_user} and activity_type IN ('want to see','saw')")
          if linked_user_activity.blank? && linked_user.subscribe_notification
            log = EmailNotifLog.where("user_id = #{l_user} and related_user_id = #{mov_user_id} and date(created_at) = '#{Date.today}'") 
            if log.blank?
              EmailNotifLog.create(:user_id => l_user ,:related_user_id=> mov_user_id ,:object_id => t_movie.to_i, :object_type => 'Movie')
              if l_user == mov_user_id
                puts "duplicate+++++++++++++++"
              end
              #NotifyMailer.notify_movie(l_user,t_movie.to_i,mov_user_id)
            end
          end
        end
      end
    end
    

    @top_celebs.each do |t_celeb|
      celeb_id = t_celeb.followable_id
      celeb_activities = []
      activities = Follow.select("follower_id").where(:followable_id => celeb_id,:followable_type => "Celebrity",:follower_type => 'User',:created_at => (Date.today - (days-1))..(Date.today+1))
      activities.each do |act|
        celeb_activities << act.follower_id
      end
      celeb_activs = celeb_activities.uniq
      celeb_activs.each do |celeb_user_id|
        MailerHelper.linked_users(celeb_user_id)
        @linked_users.each do |l_user|
          linked_user = User.find_by_id(l_user)
          linked_user_activity = Follow.where("followable_id = #{celeb_id} and followable_type = 'Celebrity' and follower_id = #{l_user} and follower_type = 'User'")
          if linked_user_activity.blank?  && linked_user.subscribe_notification
            #log = EmailNotifLog.where("user_id = #{l_user} and object_id = #{celeb_id} and object_type = 'Celebrity'")
            log = EmailNotifLog.where("user_id = #{l_user} and related_user_id = #{celeb_user_id} and date(created_at) = '#{Date.today}'")
            if log.blank?
              EmailNotifLog.create(:user_id => l_user ,:related_user_id=> celeb_user_id ,:object_id => celeb_id, :object_type => 'Celebrity')
              #NotifyMailer.notify_celebrity(l_user,celeb_id,celeb_user_id)
            end
          end
        end
      end
    end

    @top_lists.each do |t_list|
      list_id = t_list.followable_id
      list_activities = []
      activities = Follow.select("follower_id").where(:followable_id => list_id,:followable_type => "UserMovieList",:follower_type => 'User')
      activities.each do |act|
        list_activities << act.follower_id
      end
      list_activs = list_activities.uniq
      list_activs.each do |list_user_id|
        MailerHelper.linked_users(list_user_id)
        @linked_users.each do |l_user|
          linked_user = User.find_by_id(l_user)
          linked_user_activity = Follow.where("followable_id = #{list_id} and followable_type = 'UserMovieList' and follower_id = #{l_user} and follower_type = 'User'")
          if linked_user_activity.blank?  && linked_user.subscribe_notification
            #log = EmailNotifLog.where("user_id = #{l_user} and object_id = #{list_id} and object_type = 'UserMovieList'")
            log = EmailNotifLog.where("user_id = #{l_user} and related_user_id = #{list_user_id} and date(created_at) = '#{Date.today}'")
            if log.blank?
              EmailNotifLog.create(:user_id => l_user ,:related_user_id=> list_user_id ,:object_id => list_id, :object_type => 'UserMovieList')
              #NotifyMailer.notify_list(l_user,list_id,list_user_id)
            end
          end
        end
      end
    end
  end


  def self.notify_english_movie(movie_id)
    MailerHelper.send_movie_notification(movie_id,"English")
  end

  def self.notify_hindi_movie(movie_id)
    MailerHelper.send_movie_notification(movie_id,"Hindi")
  end

  def self.notify_telugu_movie(movie_id)
    MailerHelper.send_movie_notification(movie_id,"Telugu")
  end

  def self.notify_tamil_movie(movie_id)
    MailerHelper.send_movie_notification(movie_id,"Tamil")
  end
  
  def self.notify_kannada_movie(movie_id)
    MailerHelper.send_movie_notification(movie_id,"Kannada")
  end

  def self.send_movie_notification(movie_id,language)
    @users = User.where("email IS NOT NULL and (last_sign_in_at BETWEEN  '#{(Date.today-180)}' AND '#{Date.today+1}' OR date(created_at) BETWEEN  '#{(Date.today-90)}' AND '#{Date.today+1}') and sign_in_count > 0 and is_disabled = 'false'  and subscribe_newsletter = true")
    @users.each do |user|
      user_lang = []
      begin
        user_lang = ActiveSupport::JSON.decode(user.language) if !user.language.blank?
      rescue
        puts user.language
      end
      unless user_lang.blank?
        user_lang.each do |lang|
          if lang == language && !user.email.blank?
            user_activity = AllActivity.where("movie_id = #{movie_id} and user_id = #{user.id} and activity_type IN ('want to see','saw')")
            if user_activity.blank?
              log = EmailNotifLog.where("user_id = #{user.id} and object_id = #{movie_id} and object_type = 'Movie'")
              if log.blank?
                EmailNotifLog.create(:user_id => user.id ,:related_user_id=> 5 ,:object_id => movie_id, :object_type => 'Movie')
                NotifyMailer.notify_movie(user.id,movie_id,5)
              end
            end
          end
        end
      end
    end
  end

  def self.notify_movie_all(hol_movie_id,bol_movie_id,tel_movie_id,tam_movie_id)
    movie_id = ""
    @users = User.where("email IS NOT NULL and (last_sign_in_at BETWEEN  '#{(Date.today-180)}' AND '#{Date.today}' OR date(created_at) BETWEEN  '#{(Date.today-90)}' AND '#{Date.today}') and sign_in_count > 0 and is_disabled = 'false'  and subscribe_newsletter = true")
    @users.each do |user|
      user_lang = []
      user_lang = ActiveSupport::JSON.decode(user.language) if !user.language.blank?
      unless user_lang.blank?
        user_lang.each do |lang|
          if lang == "English"
            movie_id = hol_movie_id
          elsif lang == "Hindi"
            movie_id = bol_movie_id
          elsif lang == "Telugu"
            movie_id = tel_movie_id
          else
            movie_id = tam_movie_id
          end
          if !user.email.blank? && !movie_id.blank?
            user_activity = AllActivity.where("movie_id = #{movie_id} and user_id = #{user.id} and activity_type IN ('want to see','saw')")
            if user_activity.blank?
              log = EmailNotifLog.where("user_id = #{user.id} and object_id = #{movie_id} and object_type = 'Movie'")
              if log.blank?
                EmailNotifLog.create(:user_id => user.id ,:related_user_id=> 5 ,:object_id => movie_id, :object_type => 'Movie')
                NotifyMailer.notify_movie(user.id,movie_id,5)
              end
            end
          end
        end
      end
    end
  end

  def self.notify_celebrity_all(celebrity_id)
    @users = User.where("email IS NOT NULL and (last_sign_in_at BETWEEN  '#{(Date.today-90)}' AND '#{Date.today}' OR date(created_at) BETWEEN  '#{(Date.today-90)}' AND '#{Date.today}') and sign_in_count > 0 and is_disabled = 'false'  and subscribe_notification = true")
    @users.each do |user|
      if !user.email.blank?
        user_activity = Follow.where("followable_id = #{celebrity_id} and followable_type = 'Celebrity' and follower_id = #{user.id} and follower_type = 'User'")
        if user_activity.blank?
          log = EmailNotifLog.where("user_id = #{user.id} and object_id = #{celebrity_id} and object_type = 'Celebrity'")
          if log.blank?
            EmailNotifLog.create(:user_id => user.id ,:related_user_id=> 5 ,:object_id => celebrity_id, :object_type => 'Celebrity')
            NotifyMailer.notify_celebrity(user.id,celebrity_id,5)
          end
        end
      end
    end
  end

  def self.notify_list_all(list_id)
    @users = User.where("email IS NOT NULL and (last_sign_in_at BETWEEN  '#{(Date.today-360)}' AND '#{Date.today - 90}' OR date(created_at) BETWEEN  '#{(Date.today-90)}' AND '#{Date.today}') and sign_in_count > 0 and is_disabled = 'false'  and subscribe_notification = true")
    @users.each do |user|
      if !user.email.blank?
        user_activity = Follow.where("followable_id = #{list_id} and followable_type = 'UserMovieList' and follower_id = #{user.id} and follower_type = 'User'")
        if user_activity.blank?
          log = EmailNotifLog.where("user_id = #{user.id} and object_id = #{list_id} and object_type = 'UserMovieList'")
          if log.blank?
            EmailNotifLog.create(:user_id => user.id ,:related_user_id=> 5 ,:object_id => list_id, :object_type => 'UserMovieList')
            NotifyMailer.notify_list(user.id,list_id,5)
          end
        end
      end
    end
  end

  def self.extract_relateduser(obj_id)
    list_followers = []
    related_followers = []
    list = UserMovieList.find_by_id(obj_id)
    list.followers.each do |lf|
      list_followers << lf.id
    end
    all_list = UserMovieList.where("user_id = #{list.user_id} and tag != ''")
    all_list.each do |lst|
      lst.followers.each do |lf|
        related_followers << lf.id
      end
    end
    related_followers = related_followers.uniq - list_followers
    puts "list followers: "
    p(list_followers)
    puts "related followers: "
    p(related_followers)
  end

  def self.unlinked_users
    related_users = []
    all_user = []
    @users = User.select("id").where("id != 5")
    @users.each do |user|
      all_user << user.id
    end
    @lists = UserMovieList.where("tag != ''")
    @lists.each do |list|
      followers = Follow.where("followable_id = #{list.id} and followable_type = 'UserMovieList' and follower_type = 'User'")
      followers.each do |follower|
        related_users << follower.follower_id
      end
    end
    related_users = related_users.uniq
    un_related_users = all_user - related_users
    p(un_related_users)
  end
end
