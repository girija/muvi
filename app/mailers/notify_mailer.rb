class NotifyMailer < ActionMailer::Base
  require 'mandrill'
  default :from => "info@muvi.com"
  def notify_movie(user_id,data_id,related_user_id,activity_type='',notif_id='')
    json_array = {} 
    movie = Movie.find_by_id(data_id)
    @user = User.find_by_id(user_id)
    related_user = User.find_by_id(related_user_id)
    json_array["name"] = movie.name
    json_array["poster"] = "#{POSTER_URL}#{movie.banner_image_medium}"
    json_array["url"] = "http://www.muvi.com/movies/#{movie.permalink}";
    casts = movie.get_first_two_actors.split(",")
    cast_links =  movie.get_first_two_actors_link.split(",")
    json_array["cast_name1"] = casts[0]
    json_array["cast_name2"] = casts[1]
    cast_split1 =  cast_links[0].nil? ? "" : cast_links[0].split("href='")
    cast1_link =  cast_split1[1].nil? ? "" : cast_split1[1].split("'") 
    cast_split2 =  cast_links[1].nil? ? "" : cast_links[1].split("href='")
    cast2_link =  cast_split2[1].nil? ? "" : cast_split2[1].split("'")
    json_array["cast_name1_url"] = "http://www.muvi.com#{cast1_link[0]}"
    json_array["cast_name2_url"] = "http://www.muvi.com#{cast2_link[0]}"
    poster_block = "<a href='http://www.muvi.com/movies/#{movie.permalink}'><img width='64' height='94' src='#{POSTER_URL}#{movie.banner_image_medium}'></a>"
    name_block = "<a href='http://www.muvi.com/movies/#{movie.permalink}' style='text-decoration:none;color:#494949;'>#{movie.name}</a>"
    cast_1 = "<a href='http://www.muvi.com#{cast1_link[0]}' style='text-decoration:none;'>#{casts[0]}</a>"
    cast_2 = "<a href='http://www.muvi.com#{cast2_link[0]}' style='text-decoration:none;'>#{casts[1]}</a>"
    @my_wanna_see_movies = []
    @my_seen_movies = []
    wannasee_list = []
    seen_list = []
    list = ListOfMovie.find_by_user_id(user_id) 
    related_list = ListOfMovie.find_by_user_id(related_user_id)
    begin
      related_wanna_see_list = (related_list.nil? or related_list.blank?) ? [] : (related_list.wanna_see_lists.blank? ? [] : ActiveSupport::JSON.decode(related_list.wanna_see_lists))
    end
    related_seen_list = related_list.nil? ? [] : (related_list.seen_lists.blank? ? [] : ActiveSupport::JSON.decode(related_list.seen_lists))
    if list && !list.wanna_see_lists.blank?
      wannasee_list = ActiveSupport::JSON.decode(list.wanna_see_lists)
      if wannasee_list
        wannasee_list.each do |wanna_see|
          @my_wanna_see_movies << wanna_see["object"]["id"].to_i
        end
      end
    end
    if list && !list.seen_lists.blank?
      seen_list = ActiveSupport::JSON.decode(list.seen_lists)
      if seen_list
        seen_list.each do |seen|
          unless seen["object"].blank?
            @my_seen_movies << seen["object"]["id"].to_i
          end
        end
      end
    end
    @my_rated_movies = []
    rated =  UserMovieList.where(:user_id => user_id)
    if rated
      rated.each do |rate|
        if !rate.movie_id.blank?
          rated_list = ActiveSupport::JSON.decode(rate.movie_id)
          rated_list.each do |movie|
            @my_rated_movies << movie.to_i
          end
        end
      end
    end
    if movie.release_date.blank? or movie.release_date > Date.today
      upcoming = true
    else
      upcoming = false
    end
    rated = "disable"
    seen = "enable"
    wanna_see = "enable"
    if upcoming
      seen = "disable"
      rated = "disable"
      wanna_see = "enable"
    else
      if @my_seen_movies.include? (movie.id)
        if @my_rated_movies.include? (movie.id)
          rated = "success"
          seen = "disable"
          wanna_see = "disable"
        else
          rated = "enable"
          seen = "enable"
          wanna_see = "disable"
        end
      elsif @my_wanna_see_movies.include? (movie.id)
        rated = "disable"
        seen = "enable"
        wanna_see = "success"          
      end
    end
    if activity_type == "want to see"
      subject = "Ask #{related_user.display_name} for reccomendation on #{movie.name}"
      mail_header = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'>#{related_user.display_name}</a> has seen <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>, ask her for reccomendation."
    elsif activity_type == "asked"
      subject = "Do you reccomend #{related_user.display_name} to #{movie.name}"
      mail_header = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'>#{related_user.display_name}</a> wants to see <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>, do you recomend?"
    elsif activity_type == "has recommended" or activity_type == "has not recommended"
      subject = "#{related_user.display_name} #{activity_type} #{movie.name}"
      mail_header = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'>#{related_user.display_name}</a> #{activity_type} to watch <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>."
    elsif activity_type == "thanked"
      subject = "#{related_user.display_name} thanked you for #{movie.name}"
      notif = AllNotification.where("user_id = #{related_user.id} and target_user_id = #{@user.id} and movie_id = #{movie.id}").first
      if notif
	noti_json = JSON.parse(notif[:notification])
        noti_text = noti_json[0]["action_text"]
        if noti_text == "you for your recommendation"
          mail_header = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'>#{related_user.display_name}</a> has thanked you for  recommending <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>."
        else
          mail_header = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'>#{related_user.display_name}</a> has thanked you for not recommending <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>."
        end
      else
        mail_header = ""
      end
    else 
      if(related_user_id == 5)
        mail_header = "A lot of people in Muvi are talking about <a href='http://www.muvi.com/movies/#{movie.permalink}'>#{movie.name}</a>, have you seen it?"
        subject = "New Muvi for you."
      else
        if related_wanna_see_list.include? (movie.id) or upcoming
          mail_header = "#{related_user.display_name} added movie '#{movie.name}' to wanna see list. Do you want to add ?"
          subject = "#{related_user.display_name} wants to see #{movie.name}"
        else
          mail_header = "#{related_user.display_name} saw  '#{movie.name}' . Do you want to see ?"
          subject = "#{related_user.display_name} has seen #{movie.name}"
        end
      end
    end
    json_array["rated"] = rated
    json_array["seen"] = seen
    json_array["wanna_see"] = wanna_see
    if activity_type == "want to see"
      ask_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=add_activity&movie_id=#{movie.id}&notification_id=#{notif_id}&current_user_id=#{@user.id}&target_user_id=#{related_user.id}&activity_type=asked"
      ask_btn = "<a href='#{ask_url}' style='text-decoration:none;color:#fff;'>Ask</a>"
    elsif activity_type == "asked"
      yes_recomend_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=add_activity&movie_id=#{movie.id}&notification_id=#{notif_id}&current_user_id=#{@user.id}&target_user_id=#{related_user.id}&activity_type=has recommended"
      no_recomend_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=add_activity&movie_id=#{movie.id}&notification_id=#{notif_id}&current_user_id=#{@user.id}&target_user_id=#{related_user.id}&activity_type=has not recommended"
      yes_recomend_btn = "<a href='#{yes_recomend_url}' style='text-decoration:none;color:#fff;'>Yes</a>"
      no_recomend_btn = "<a href='#{no_recomend_url}' style='text-decoration:none;color:#fff;'>No</a>"
    elsif activity_type == "has recommended" || activity_type == "has not recommended"
      thanks_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=add_activity&movie_id=#{movie.id}&notification_id=#{notif_id}&current_user_id=#{@user.id}&target_user_id=#{related_user.id}&activity_type=thanked"
      thanks_btn = "<a href='#{thanks_url}' style='text-decoration:none;color:#fff;'>Thanks</a>"
    else
      if upcoming
        seen_btn = ""
        wanna_see_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=wanna_see&movie_id=#{movie.id}"
        json_array["wanna_see_url"] = wanna_see_url
        wanna_see_btn = "<a href='#{wanna_see_url}' style='text-decoration:none;color:#fff;'>Wanna See</a>"
      else
        seen_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=have_seen&movie_id=#{movie.id}"
        json_array["seen_url"] = seen_url
        seen_btn = "<a href='#{seen_url}' style='text-decoration:none;color:#fff;'>Seen</a>"
        wanna_see_url = "http://www.muvi.com/url_activity/#{@user.authentication_token}?activity=wanna_see&movie_id=#{movie.id}"
        json_array["wanna_see_url"] = wanna_see_url
        wanna_see_btn = "<a href='#{wanna_see_url}' style='text-decoration:none;color:#fff;'>Wanna See</a>"
      end
    end
    @data = json_array.to_json
    @display_name = @user.display_name
    @new_title = "#{related_user.display_name} has seen #{movie.name}"
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    if activity_type == "want to see"
      template_name = "movie_ask"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"story_block","content"=>movie.story},{"name"=>"ask_btn","content"=>ask_btn},{"name"=>"cast1","content"=>cast_1},{"name"=>"cast2","content"=>cast_2},{"name"=>"user_name","content" => @user.display_name},{"name"=>"subject_line","content"=>mail_header}]

    elsif activity_type == "asked"
      puts "asked recomed temp"
      template_name = "movie_recomend"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"story_block","content"=>movie.story},{"name"=>"yes_recomend_btn","content"=>yes_recomend_btn},{"name"=>"no_recomend_btn","content"=>no_recomend_btn},{"name"=>"cast1","content"=>cast_1},{"name"=>"cast2","content"=>cast_2},{"name"=>"user_name","content" => @user.display_name},{"name"=>"subject_line","content"=>mail_header}]
    elsif activity_type == "has recommended" || activity_type == "has not recommended"
      template_name = "movie_thanks"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"story_block","content"=>movie.story},{"name"=>"thanks_btn","content"=>thanks_btn},{"name"=>"cast1","content"=>cast_1},{"name"=>"cast2","content"=>cast_2},{"name"=>"user_name","content" => @user.display_name},{"name"=>"subject_line","content"=>mail_header}]
    elsif activity_type == "thanked"
      poster_block = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}'><img width='64' height='94' src='#{POSTER_URL}#{related_user.user_image}'></a>"
      name_block = "<a href='http://www.muvi.com/profile/#{related_user.id}/#{related_user.display_name}' style='text-decoration:none;color:#494949;'>#{related_user.display_name}</a>"
      template_name = "movie_after_thanks"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"story_block","content"=>movie.story},{"name"=>"cast1","content"=>cast_1},{"name"=>"cast2","content"=>cast_2},{"name"=>"user_name","content" => @user.display_name},{"name"=>"subject_line","content"=>mail_header}]
    else
      if upcoming
        template_name = "movie_wanna_see"
      else
        template_name = "movie_seen_wanna_see"
      end
      if movie.story.blank?
        story_block = ""
      else
        story_block = '<tr><td style="font-size:14px;font-family:Arial, Helvetica, sans-serif">"'+movie.story+'"</td></tr>'
      end
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"story_block","content"=>story_block},{"name"=>"seen_btn","content"=>seen_btn},{"name"=>"wanna_see_btn","content"=>wanna_see_btn},{"name"=>"cast1","content"=>cast_1},{"name"=>"cast2","content"=>cast_2},{"name"=>"user_name","content" => @user.display_name},{"name"=>"subject_line","content"=>mail_header}]
    end
    message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>@user.email, "name"=>@user.display_name}],"subject"=>subject}
    async = false
    ip_pool = "Main Pool"
    send_at = Date.today 
    if mail_header != ""
      result = mandrill.messages.send_template template_name, template_content, message#, async, ip_pool, send_at
    end
    p(result)
    #mail(:to =>@user.email, :subject => subject,:from=>"info@muvi.com").deliver
  end

  def notify_list(user_id,list_id,related_user_id)
    json_array = {}
    list = UserMovieList.find_by_id(list_id)
    if list
      user = User.find_by_id(user_id)
      related_user = User.find_by_id(related_user_id)
      creator = User.find_by_id(list.user_id)
      last_movie = Movie.find_by_id(ActiveSupport::JSON.decode(list.movie_id).last.to_i)
      json_array["name"] = list.tag
      json_array["url"] = "http://www.muvi.com/movie_list/#{list.id}/#{list.tag}"
      json_array["poster"] = "#{POSTER_URL}#{last_movie.banner_image_medium}"
      json_array["creator"] = creator.display_name
      json_array["creator_link"] = "http://www.muvi.com/profile/#{creator.id}/#{creator.display_name}"
      poster_block = "<a href='http://www.muvi.com/movie_list/#{list.id}/#{list.tag}'><img width='64' height='94' src='#{POSTER_URL}#{last_movie.banner_image_medium}'></a>"
      name_block = "<a href='http://www.muvi.com/movie_list/#{list.id}/#{list.tag}' style='text-decoration:none;color:#494949;'>#{list.tag}</a>"
      creator_link = "<a href='http://www.muvi.com/profile/#{creator.id}/#{creator.display_name}'>#{creator.display_name}</a>"
      follow = "disable"
      if user_id !=  creator.id
        if !list.followed_by?(user)
          follow = "enable"
        else
          follow = "success"
        end
      end
      json_array["follow"] = follow
      if follow == "enable"
        follow_url = "http://www.muvi.com/url_activity/#{user.authentication_token}?activity=follow_list&list_id=#{list.id}"
        json_array["follow_url"] = follow_url
        follow_btn = "<a href='#{follow_url}' style='text-decoration:none;color:#fff;'>Follow</a>"
      else
        follow_btn = "Following"
      end
      @data = json_array.to_json
      @display_name = user.display_name
      @new_title = "#{related_user.display_name} followed #{list.tag}"
      if(related_user_id == 5)
        mail_header = "<a href='http://www.muvi.com/movie_list/#{list.id}/#{list.tag}'>#{list.tag}</a> is awesome have you followed it yet?"
        subject = list.tag
      else
	mail_header = "#{related_user.display_name} follows list '#{list.tag}'. Do you want to follow ?"
        subject = "#{related_user.display_name} followed list #{list.tag}"
      end
      mandrill = Mandrill::API.new MANDRILL_API_KEY
      template_name = "list"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"btn_block","content"=>follow_btn},{"name"=>"user_name","content" => user.display_name},{"name"=>"subject_line","content"=>mail_header},{"name"=>"creator_link","content"=>creator_link}]
      message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
      async = false
      ip_pool = "Main Pool"
      send_at = Date.today
      result = mandrill.messages.send_template template_name, template_content, message#, async, ip_pool, send_at
      p(result)
      #mail(:to =>user.email, :subject => subject,:from=>"info@muvi.com").deliver
    end
  end

  def notify_celebrity(user_id,data_id,related_user_id)
    json_array = {}
    celeb = Celebrity.find_by_id(data_id)
    user = User.find_by_id(user_id)
    related_user = User.find_by_id(related_user_id)
    json_array["name"] = celeb.name
    json_array["poster"] = "#{POSTER_URL}#{celeb.image}"
    poster_block = "<a href='http://www.muvi.com/stars/#{celeb.permalink}'><img width='64' height='94' src='#{POSTER_URL}#{celeb.image}'></a>"
    name_block = "<a href='http://www.muvi.com/stars/#{celeb.permalink}' style='text-decoration:none;color:#494949;'>#{celeb.name}</a>"
    json_array["url"] = "http://www.muvi.com/stars/#{celeb.permalink}"
    follow = "disable"
    if !celeb.followed_by?(user)
      follow = "enable"
    else
      follow = "success"
    end
    if follow == "enable"
      follow_url = "http://www.muvi.com/url_activity/#{user.authentication_token}?activity=follow_celeb&celeb_id=#{celeb.id}"
      json_array["follow_url"] = follow_url
      follow_btn = "<a href='#{follow_url}' style='text-decoration:none;color:#fff;'>Follow</a>"
    else
      follow_btn = "Following"
    end
    json_array["follow"] = follow
    @data = json_array.to_json
    @display_name = user.display_name
    @new_title = "#{related_user.display_name} followed #{celeb.name}"
    if(related_user_id == 5)
      mail_header = "<a href='http://www.muvi.com/stars/#{celeb.permalink}'>#{celeb.name}</a> has a few interesting movies coming up. Follow filmography to get notified when new movie is announced"
      subject = "Fanhood invitation."
    else
      mail_header = "#{related_user.display_name} follows filmography of '#{celeb.name}'. Do you want to follow ?"
      subject = "#{related_user.display_name} following #{celeb.name}'s filmography"
    end
    mandrill = Mandrill::API.new MANDRILL_API_KEY
    template_name = "celebrity"
    template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"btn_block","content"=>follow_btn},{"name"=>"user_name","content" => user.display_name},{"name"=>"subject_line","content"=>mail_header}]
    message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
    async = false
    ip_pool = "Main Pool"
    send_at = Date.today
    result = mandrill.messages.send_template template_name, template_content, message#, async, ip_pool, send_at
    p(result)
    #mail(:to =>"sanjib.parida@exelanz.com", :subject => subject,:from=>"info@muvi.com").deliver
  end

  def self.send_notification_unrelated_user(user_id,list_id,subject,mail_header)
    json_array = {}
    list = UserMovieList.find_by_id(list_id)
    if list
      user = User.find_by_id(user_id)
      creator = User.find_by_id(list.user_id)
      last_movie = Movie.find_by_id(ActiveSupport::JSON.decode(list.movie_id).last.to_i)
      json_array["name"] = list.tag
      json_array["url"] = "http://www.muvi.com/movie_list/#{list.id}/#{list.tag}"
      json_array["poster"] = "#{POSTER_URL}#{last_movie.banner_image_medium}"
      json_array["creator"] = creator.display_name
      json_array["creator_link"] = "http://www.muvi.com/profile/#{creator.id}/#{creator.display_name}"
      poster_block = "<a href='http://www.muvi.com/movie_list/#{list.id}/#{list.tag}'><img width='64' height='94' src='#{POSTER_URL}#{last_movie.banner_image_medium}'></a>"
      name_block = "<a href='http://www.muvi.com/movie_list/#{list.id}/#{list.tag}' style='text-decoration:none;color:#494949;'>#{list.tag}</a>"
      follow_url = "http://www.muvi.com/url_activity/#{user.authentication_token}?activity=follow_list&list_id=#{list.id}"
      json_array["follow_url"] = follow_url
      follow_btn = "<a href='#{follow_url}' style='text-decoration:none;color:#fff;'>Follow</a>"
      @display_name = user.display_name
      mandrill = Mandrill::API.new MANDRILL_API_KEY
      template_name = "list"
      template_content = [{"name"=>"name", "content"=>name_block},{"name"=>"poster_block","content"=>poster_block},{"name"=>"btn_block","content"=>follow_btn},{"name"=>"user_name","content" => user.display_name},{"name"=>"subject_line","content"=>mail_header}]
      message = {"from_email"=>"info@muvi.com","from_name"=>"Muvi","to"=>[{"email"=>user.email, "name"=>user.display_name}],"subject"=>subject}
      result = mandrill.messages.send_template template_name, template_content, message
      p(result)
    end
  end

  def test_mail
    mail(:to =>"sanjib.parida@exelanz.com", :subject => "test email",:from=>"info@muvi.com").deliver
  end
end

