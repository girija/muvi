class DisplayController < ApplicationController
  skip_before_filter :authenticate_user!, :verify_authenticity_token
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  respond_to :json, :xml 
  def index
    @items = HomePageSetting.find(:all)
    items = []
    @items.each do |item|
      i = {}
      i['item_type'] = item.subject_type
      i['item_id'] = item.subject_id
      items << i
    end
    response = {:items => items}
    respond_to do |format|
      format.html { render :action => 'index'}
      format.xml  { render :xml => items.to_xml}
      format.json { render :json => items.to_json, :content_type => "text/javascript" }
    end
    #render :json => response
  end
  def item_details
    expires_in 3.minutes
    case params[:item_type]
    when 'movie'
      movie = Movie.find_by_id(params[:item_id])
      m = {}
      m["reload"] = params[:reload]
      m["type"] = params[:item_type]
      m["id"] =  movie.id
      m["name"] =  movie.name
      m["path"] = movie_path(movie.permalink)
      if !movie.release_date.blank?
       release_text = movie.release_date <= Date.today ? 'In Theaters' : 'Upcoming'
      else
       release_text = 'Upcoming'
      end
      m["meter"] = movie.muvimeter
      cr = movie.critics_reviews
      if release_text == 'Upcoming'
        m["is_upcoming"] = true
      else
        m["is_upcoming"] = false
      end

      if !cr.blank?
        m["critics_review"] = true
      else
        m["critics_review"] = false
      end
      m["images"] = {}
      m["images"]["url"] = movie.banner_image
      if release_text == 'In Theaters'
        m["count_text"] =  "#{movie.review_users('like').size} liked"
      else
        #m["count_text"] = "#{movie.review_users('like').size} likes"
        want_1 = movie.want_to_sees
        want = want_1.collect {|x| x.user_id}.uniq
        m["count_text"] = "#{want.size} see"
      end
      m["comments"] = []
      comment = {}
      movie.discussions.reverse.first(3).each do |discussion|
        comment = {}
        comment["id"] = discussion.id
        comment["question"] = discussion.question
        #comment["description"] = discussion.description
        comment["user"] = {}
        comment["user"]["id"] = discussion.user_id
        user = User.find_by_id(discussion.user_id)
        if user
          user_profile = UserProfile.find_by_user_id(discussion.user_id)
          comment["user"]["name"] = user_profile.display_name
          comment["user"]["image"] = user.user_image
          comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
          m["comments"] <<  comment
        end
      end
      m["mouseover"] = []
      ctr = 0
      @actors = []
      movie.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
        end
      end
      @actors.each do |act|
        cast = {}
        unless act.celebrity.blank?
          cast["id"] = act.celebrity.id
          cast["name"] = act.celebrity.name
          cast["path"] = star_path(act.celebrity.permalink)
          cast['image'] = act.celebrity.medium_image
        end
        if ctr  == 2
           break
        end
        ctr = ctr + 1
        m["mouseover"] << cast
      end
      p(m)
      video_id = ""
      video = ""
      videoids = ''
      tagging = Tagging.find(:all, :conditions => ["taggable_type='Video' and tagger_type='Movie' and tagger_id = ?",movie.id], :select => "taggable_id")
      unless tagging.blank?
        tagging.each do |t|
          if !t.taggable_id.blank?
            if video_id.blank?
              video_id = t.taggable_id
            else
              video_id = video_id.to_s + "," + t.taggable_id.to_s
            end
          end
        end
      end
      if video_id != ""
        video = Tagging.where("taggable_id IN (#{video_id})").find(:all, :conditions => ["lower(tagger_type) = 'trailer'"], :select => "taggable_id", :order => ["id desc"]) 
      end
      unless video_id.blank?
        unless video.blank?
          videoids = ""
          video.each do |v|
            if videoids.blank?
              videoids = v.taggable_id
            else
              videoids = videoids.to_s + "," + v.taggable_id.to_s
            end
          end
        end
      end
      if videoids != ''
       video = Video.where("id IN (#{videoids})").find(:all,:conditions => ["rank = 1"]).first
       unless video.blank?
         m["trailer"] = video.id
       end
      end
      
      m["data"] = {}
      unless params[:current_user].blank?
        list = ListOfMovie.find_by_user_id(params[:current_user])
        if list && !list.wanna_see_lists.blank?
          wannasee_list = ActiveSupport::JSON.decode(list.wanna_see_lists)
          wannasee_list.each do |wanna_see|
            if wanna_see["object"]["id"] == params[:item_id]
              m["data"]["watch"] = 1
            else
              m["data"]["watch"] = 0
            end
          end
        end
        if release_text != 'Upcoming'
          if list && !list.seen_lists.blank?
            seen_list = ActiveSupport::JSON.decode(list.seen_lists)
            seen_list.each do |seen|
              if seen["object"]["id"] == params[:item_id]
                m["data"]["seenit"] = 1
                break
              else
                m["data"]["seenit"] = 0
              end
            end
          end
          if m["data"]["seenit"] == 0
            rating = Review.find(:all, :conditions => ["user_id = ? AND movie_id = ?", params[:current_user], params[:item_id]]).first
            unless rating.blank?
              m["data"]["seenit"] = 1
            end
          else
            rating = Review.find(:all, :conditions => ["user_id = ? AND movie_id = ?", params[:current_user], params[:item_id]]).first
            unless rating.blank?
              if rating.rating.to_i > 3
                m["data"]["like"] = 1
                m["data"]["dislike"] = 0
              else
                m["data"]["like"] = 0
                m["data"]["dislike"] = 1
              end
              m["data"]["comment"] = rating.description
            end         
          end
        end
      else
        m["data"]["watch"] = 0
        m["data"]["seenit"] = 0
      end
      m["flag"] = params[:flag]
      item = []
      item << m
      render :json => item
    when 'star'
      star = Celebrity.find_by_id(params[:item_id])
      s = {}
      s["reload"] = params[:reload]
      s["type"] = params[:item_type]
      s["id"] =  star.id
      s["name"] = star.name
#        s["birthdate"] = star.birthdate
      s["path"] = star_path(star.permalink)
      s['meter'] = star.popularity
      s["images"] = {}
      s["images"]["url"] = star.large_image
      s["count_text"] =  "#{star.fans.size} fans"
      unless params[:current_user].blank?
        s["current_user_fan"] = Fan.find(:all, :select => ["id"], :conditions =>["user_id = ? AND celebrity_id = ?", params[:current_user],star.id]).size
      end
      s["comments"] = []
      comment = {}
      star_discussion = star.discussions.reverse.first(3)
      star_tweets = star.celebrity_tweets.limit(3)
      #star_comment = (((star_discussion + star_tweets).sort_by &:score).reverse)[0..2]
      star_comment = (((star_discussion + star_tweets).sort_by &:created_at).reverse)[0..2]

      if !star_comment.blank?
        star_comment.each do |discussion_tweet|
          if discussion_tweet.class.to_s == "Discussion"
            comment = {}
            comment["id"] = discussion_tweet.id
            comment["question"] = discussion_tweet.question
            comment["user"] = {}
            comment["user"]["id"] = discussion_tweet.user_id
            user = User.find(discussion_tweet.user_id)
            user_profile = UserProfile.find_by_user_id(discussion_tweet.user_id)
            comment["user"]["name"] = user_profile.display_name
            comment["user"]["image"] = user.user_image
            comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
            s["comments"] <<  comment
          else
            comment = {}
            comment["id"] = discussion_tweet.id
            comment["question"] = discussion_tweet.content
            comment["user"] = {}
            comment["user"]["id"] = discussion_tweet.celebrity_id
            comment["user"]["name"] = discussion_tweet.twitter_screen_name
            comment["user"]["image"] = star.thumb_image
            comment["user"]["path"] = "/stars/#{star.permalink}"
            s["comments"] <<  comment
          end
        end
      end

      @movie = []
      @movie_blank_release = []
      star.movie_casts.find(:all, :select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"], :order => ["movie_id asc"]).each do |mov_cast|
        @movie_release = mov_cast.movie
        unless @movie_release.blank?
          if !@movie_release.release_date.blank? and @movie_release.release_date > Date.today
            @movie << @movie_release
          elsif @movie_release.release_date.blank?
            @movie_blank_release << @movie_release
          end
        end
      end
      @movie.uniq
      unless @movie.blank?
        @movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
      end
      @movie = @movie | @movie_blank_release
      s["mouseover"] = []
      ctr = 0
      @movie.each do |movie|
        cast = {}
        cast["id"] = movie.id
        cast["name"] = movie.name
        cast["path"] = movie_path(movie.permalink)
        cast['image'] = movie.banner_image_medium
        if ctr  == 2
           break
        end
        ctr = ctr + 1
        s["mouseover"] << cast
      end
      s["upcoming"] = []
      @movie = []
      @movie_blank_release = []     
      star.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"], :order => ["movie_id asc"]).each do |mov_cast|
        @movie_release = mov_cast.movie
        unless @movie_release.blank?
          if !@movie_release.release_date.blank? and @movie_release.release_date > Date.today
            @movie << @movie_release
          elsif @movie_release.release_date.blank?
            @movie_blank_release << @movie_release
          end
        end
      end
      @movie.uniq
      unless @movie.blank?
        @movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
      end
      @movie = @movie | @movie_blank_release
      @movie.each  do |movie|
        mov = {}
        mov["name"] = movie.name
        mov["path"] = movie_path(movie.permalink)
        mov['image'] = movie.banner_image_thumb
        s["upcoming"] <<  mov
        break
      end

 
      s["top_rated"] = []
      @top_movie = []
      star.movie_casts.find(:all,:select => ["movie_id"], :conditions => ["movie_id IS NOT NULL"], :group => ["movie_id"]).each do |mov_cast|
        @movie_release = mov_cast.movie
        unless @movie_release.blank?
          if !@movie_release.release_date.blank? and !@movie_release.release_date.nil? and @movie_release.release_date <= Date.today
            @top_movie << @movie_release
          end
        end
      end
      unless @top_movie.blank?
        @top_movie.uniq
        begin
          @top_movie.sort!{|b,a| a.muvimeter <=> b.muvimeter }
        rescue
        end
      end
      c = 0
      @top_movie.each  do |top_movie|
        movie = {}
        movie["name"] = top_movie.name
        movie["path"] = movie_path(top_movie.permalink)
        movie['image'] = top_movie.banner_image_medium
        s["top_rated"] <<  movie
        if c == 1
          break
        else
          c = c + 1
        end
      end
      s["data"] = {}
      unless params[:current_user].blank?
        s["data"]["fan"] = Fan.find(:all, :select => ["id"], :conditions =>["user_id = ? AND celebrity_id = ? AND is_fan = true", params[:current_user], params[:item_id]]).size
        s["data"]["unfan"] = Fan.find(:all, :select => ["id"], :conditions =>["user_id = ? AND celebrity_id = ? AND is_fan = false", params[:current_user], params[:item_id]]).size
      else
        s["data"]["fan"]=0
        s["data"]["unfan"] = 0
      end
      s["flag"] = params[:flag]
      item = []
      item << s
      render :json => item
    when 'video'
      video = Video.find_by_id(params[:item_id])
      unless video.blank?
        v = {}
        v["reload"] = params[:reload]
        v["type"] = params[:item_type]
        v["id"] = video.id
        v["name"] = video.name
        v["images"] = {}
        unless video.video_remote_url.blank?
          video_id_arr = video.video_remote_url.split("/")
          video_id = video_id_arr[video_id_arr.size.to_i - 1]
          video_src = "http://www.youtube.com/embed/#{video_id.to_s}?wmode=opaque&autoplay=1"
          video_img = "http://img.youtube.com/vi/#{video_id}/1.jpg"
        else
          video_src = video.trailer.url.to_s

          ###### Check if video thumbnail exists or not   
          #if FileTest.exists?(open( "http://dfquahprf1i3f.cloudfront.net/public/system/trailer_thumbnails/#{video.id}/1.jpg"))
          url = URI.parse(VIDEO_URL + "/system/trailer_thumbnails/#{video.id}/1.jpg") 
          req = Net::HTTP::Get.new(url.path)
          result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
          if result.code == "200"
            video_img = URL + "/system/trailer_thumbnails/#{video.id}/1.jpg"
          else
            video_img = "/images/no-image.png"
          end
        end  
        v["images"]["url"] = video_img
        v["count_text"] = "#{Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Video' and voter_type = 'User' and vote_flag = 't'").size} liked" 
        # v["video"] = video_src

        commnts = Comment.where('commentable_id = ? and commentable_type = ?',params[:item_id], 'Video').limit(3)
        v["comments"] = []
        comment = {}
        commnts.each do |commnt|
          comment = {}
          comment["id"] = commnt.id
          comment["comment"] = commnt.comment
          comment["user"] = {}
          comment["user"]["id"] = commnt.user_id
          user = User.find(commnt.user_id)
          user_profile = UserProfile.find_by_user_id(commnt.user_id)
          comment["user"]["name"] = user_profile.display_name
          comment["user"]["image"] = user.user_image
          comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
          v["comments"] <<  comment
        end
        v["mouseover"] = []
        ctr = 0
        video.taggings.each do |tagging|
          if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?     
            if tagging.tagger_type == 'Movie'
              cast = {}
              cast["id"] = tagging.tagger_id
              movie = Movie.find_by_id(tagging.tagger_id)
              cast["name"] = movie.name
              cast["path"] = movie_path(movie.permalink)
              cast['image'] = movie.banner_image
              v["mouseover"] << cast
            elsif tagging.tagger_type == 'Celebrity'
              cast = {}
              cast["id"] = tagging.tagger_id
              celeb = Celebrity.find_by_id(tagging.tagger_id)
              cast["name"] = celeb.name
              cast["path"] = star_path(celeb.permalink)
              cast['image'] = celeb.image
              v["mouseover"] << cast
            end
            if ctr  == 2
               break
            end
            ctr = ctr + 1
  #          v["mouseover"] << cast
          end
        end
        v["data"] = {}
        v["data"]["like"] = 0
        v["data"]["dislike"] = 0
        unless params[:current_user].blank?
          v["data"]["like"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Video' and voter_type = 'User' and vote_flag = 't' and voter_id = #{params[:current_user]}").size
          v["data"]["dislike"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Video' and voter_type = 'User' and vote_flag = 'f' and voter_id = #{params[:current_user]}").size
        end
        v["flag"] = params[:flag]

        item = []
        item << v
        render :json => item
      end
    when 'poster'
      poster = Poster.find_by_id(params[:item_id])
      p = {}
      p["reload"] = params[:reload]
      p["type"] = params[:item_type]
      p["id"] = poster.id
      p["name"] = poster.name
      p["images"] = {}

      #url = URI.parse(POSTER_URL + "/system/posters/#{poster.id}/crop_standard/#{Rack::Utils.escape(poster.poster_file_name)}")
      url = URI.parse(POSTER_URL + "/system/posters/#{poster.id}/crop_standard/#{poster.poster_file_name.gsub(" ", "%20")}")

      req = Net::HTTP::Get.new(url.path)
      result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
      if result.code == "200"
        p["images"]["url"] = POSTER_URL + "/system/posters/#{poster.id}/crop_standard/#{poster.poster_file_name.gsub(" ", "%20")}"
      else
        p["images"]["url"] = "/images/no-image.png"
      end
     
      p["count_text"] = "#{Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Poster' and voter_type = 'User' and vote_flag = 't'").size} liked"
      commnts = Comment.where('commentable_id = ? and commentable_type = ?',params[:item_id], 'Poster').limit(3)
      p["comments"] = []
      comment = {}
      commnts.each do |commnt|
        comment = {}
        comment["id"] = commnt.id
        comment["comment"] = commnt.comment
        comment["user"] = {}
        comment["user"]["id"] = commnt.user_id
        user = User.find(commnt.user_id)
        user_profile = UserProfile.find_by_user_id(commnt.user_id)
        comment["user"]["name"] = user_profile.display_name
        comment["user"]["image"] = user.user_image
        comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
        p["comments"] <<  comment
      end
      ctr = 0
      p["mouseover"] = []
      poster.taggings.each do |tagging|
        if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?
          if tagging.tagger_type == 'Movie'
            cast = {}
            cast["id"] = tagging.tagger_id
            movie = Movie.find_by_id(tagging.tagger_id)
            cast["name"] = movie.name
            cast["path"] = movie_path(movie.permalink)
            cast['image'] = movie.banner_image_thumb
            p["mouseover"] << cast
          elsif tagging.tagger_type == 'Celebrity'
            cast = {}
            cast["id"] = tagging.tagger_id
            celeb = Celebrity.find_by_id(tagging.tagger_id)
            cast["name"] = celeb.name
            cast["path"] = star_path(celeb.permalink)
            cast['image'] = celeb.thumb_image
            p["mouseover"] << cast
          end
          if ctr  == 2
             break
          end
          ctr = ctr + 1
#          p["mouseover"] << cast
        end
      end
      p["data"] = {}
      p["data"]["like"] = 0
      p["data"]["dislike"] = 0
      unless params[:current_user].blank?
        p["data"]["like"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Poster' and voter_type = 'User' and vote_flag = 't' and voter_id = #{params[:current_user]}").size
        p["data"]["dislike"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Poster' and voter_type = 'User' and vote_flag = 'f' and voter_id = #{params[:current_user]}").size
      end
      p["flag"] = params[:flag]

      item = []
      item << p
      render :json => item
    when 'critics'
      critics = CriticsReview.find(params[:item_id])
      c = {}
      c["id"] = critics.id
      c["summary"] = critics.summary
        #c["film_critic"] = {}
        #c["film_critic"]["id"] = critics.film_critic_id
        #c["film_critic"]["name"] = critics.film_critic.name
        #c["film_critic"]["organization"] = critics.film_critic.organization 
        #c["film_critic"]["image"] = critics.film_critic.profile_image rescue '/images/no-profile.png'
      c["count_text"] = "#{critics.likes.size} liked"
      c["comments"] = []
      comment = {}
      critics.comments.each do |commnt|
        comment = {}
        comment["id"] = commnt.id
        comment["comment"] = commnt.comment
        comment["user"] = {}
        comment["user"]["id"] = commnt.user_id
        user = User.find(commnt.user_id)
        user_profile = UserProfile.find_by_user_id(commnt.user_id)
        comment["user"]["name"] = user_profile.display_name
        comment["user"]["image"] = user.user_image
        comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
        c["comments"] <<  comment
      end
      c["data"] = {}
      unless  params[:current_user].blank?
        likes = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Critics' and voter_type = 'User' and voter_id = #{params[:current_user]}")
        c["data"]["likes"] = 0
        c["data"]["dislikes"] = 0
        unless likes.blank?
          if likes.vote_flag == 't'
            c["data"]["likes"] = 1
            c["data"]["dislikes"] = 0
          elsif likes.vote_flag == 'f'
            c["data"]["likes"] = 0
            c["data"]["dislikes"] = 1
          end
        end
      end
      c["flag"] = params[:flag]
      item = []
      item << c
      render :json => item
    when 'review'
      review =  Review.find_by_id(params[:item_id])
      r = {}
      r["id"] = review.id
      r["suumary"] = review.description
        #r["user"] = {}
        #r["user"]["id"] = review.user_id
        #user = User.find(review.user_id)
        #r["user"]["name"] = user.display_name
        #r["user"]["path"] = user.user_image
    #    r["dislikes"] = review.dislikes.size
      r["comments"] = []
      comment = {}
      review.comments.each do |commnt|
        comment = {}
        comment["id"] = commnt.id
        comment["comment"] = commnt.comment
        comment["user"] = {}
        comment["user"]["id"] = commnt.user_id
        user = User.find(commnt.user_id)
        user_profile = UserProfile.find_by_user_id(commnt.user_id)
        comment["user"]["name"] = user_profile.display_name
        comment["user"]["image"] = user.user_image
        comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
        r["comments"] <<  comment
      end
      r["data"] = {}
      unless  params[:current_user].blank?
        likes = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Review' and voter_type = 'User' and voter_id = #{params[:current_user]}")
        r["data"]["likes"] = 0
        r["data"]["dislikes"] = 0
        unless likes.blank?
          if likes.vote_flag == 't'
            r["data"]["likes"] = 1
            r["data"]["dislikes"] = 0
          elsif likes.vote_flag == 'f'
            r["data"]["likes"] = 0
            r["data"]["dislikes"] = 1
          end
        end
      end
      r["flag"] = params[:flag]
      item = []
      item << r
      render :json => r 
    when 'news'
      news =  Feed.find_by_id(params[:item_id])
      unless news.blank?
        n = {}
        n["type"] = params[:item_type]
        n["id"] = news.id
        n["title"] = news.entry_title
        n["summary"] = news.summary
        n["count_text"] = "#{news.votes.size} likes"
        n["mouseover"] = []
        ctr = 0
        path = ''
        news.taggings.each do |tagging|
          if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?      
            if tagging.tagger_type == 'Movie'
              cast = {}
              cast["id"] = tagging.tagger_id
              movie = Movie.find_by_id(tagging.tagger_id)
              cast["name"] = movie.name
              cast["path"] = movie_path(movie.permalink)
              cast['image'] = movie.banner_image_thumb
              path = "/news/movie/#{movie.permalink}/#{tagging.id}"
              n["mouseover"] << cast
            elsif tagging.tagger_type == 'Celebrity'
              cast = {}
              cast["id"] = tagging.tagger_id
              celeb = Celebrity.find_by_id(tagging.tagger_id)
              cast["name"] = celeb.name
              cast["path"] = star_path(celeb.permalink)
              cast['image'] = celeb.thumb_image
              path = "/news/star/#{celeb.permalink}/#{tagging.id}"
              n["mouseover"] << cast
            end
            if ctr  == 2
               break
            end
            ctr = ctr + 1
#            n["mouseover"] << cast
          end
        end
        n["path"] = path

        n["comments"] = []
        comment = {}
        ctr = 0
        news.comments.each do |commnt|
          comment = {}
          comment["id"] = commnt.id
          comment["comment"] = commnt.comment
          comment["user"] = {}
          comment["user"]["id"] = commnt.user_id
          user = User.find(commnt.user_id)
          user_profile = UserProfile.find_by_user_id(commnt.user_id)
          comment["user"]["name"] = user_profile.display_name
          comment["user"]["image"] = user.user_image
          comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
          n["comments"] <<  comment
          if ctr  == 2
             break
         end
          ctr = ctr + 1
        end
        n["data"] = {}
        n["data"]["like"] = 0
        n["data"]["dislike"] = 0

        unless  params[:current_user].blank?
          n["data"]["like"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Feed' and voter_type = 'User' and vote_flag = 't' and voter_id = #{params[:current_user]}").size
          n["data"]["dislike"] = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Feed' and voter_type = 'User' and vote_flag = 'f' and voter_id = #{params[:current_user]}").size
        end
      end
      n["flag"] = params[:flag]

      item = []
      item << n
      render :json => item
    when 'celebtweet'
      tweet = CelebTweet.find(params[:item_id])
      t = {}
      t["type"] = params[:item_type]
      t["id"] = tweet.id
      t["summary"] = tweet.content
      celeb = Celebrity.find_by_id(tweet.celebrity_id)
      unless celeb.blank?
        t["path"] = star_path(celeb.permalink)
        t['image'] = celeb.thumb_image
      end
      t["count_text"] = "#{tweet.votes.size} likes"  
      t["comments"] = []
      comment = {}
      ctr = 0
      tweet.comments.each do |commnt|
        comment = {}
        comment["id"] = commnt.id
        comment["comment"] = commnt.comment
        comment["user"] = {}
        comment["user"]["id"] = commnt.user_id
        user = User.find(commnt.user_id)
        user_profile = UserProfile.find_by_user_id(commnt.user_id)
        comment["user"]["name"] = user_profile.display_name
        comment["user"]["image"] = user.user_image
        comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
        t["comments"] <<  comment
        if ctr  == 2
          break
        end
        ctr = ctr + 1
      end
      t["data"] = {}
      unless  params[:current_user].blank?
        likes = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'CelebTweet' and voter_type = 'User' and voter_id = #{params[:current_user]}")
        t["data"]["likes"] = 0
        t["data"]["dislikes"] = 0
        unless likes.blank?
          if likes.vote_flag == 't'
            t["data"]["likes"] = 1
            t["data"]["dislikes"] = 0
          elsif likes.vote_flag == 'f'
            t["data"]["likes"] = 0
            t["data"]["dislikes"] = 1
          end
        end
      end
      t["flag"] = params[:flag]
      item = []
      item << t
      render :json => item
    when 'tweet'
      tweet = Tweet.find(params[:item_id])
      t = {}
      t["type"] = params[:item_type]
      t["id"] = tweet.id
      t["summary"] = tweet.content
      t["count_text"] = "#{tweet.votes.size} likes"
      t["comments"] = []
      comment = {}
      tweet.comments.each do |commnt|
        comment = {}
        comment["id"] = commnt.id
        comment["comment"] = commnt.comment
        comment["user"] = {}
        comment["user"]["id"] = commnt.user_id
        user = User.find(commnt.user_id)
        user_profile = UserProfile.find_by_user_id(commnt.user_id)
        comment["user"]["name"] = user_profile.display_name
        comment["user"]["image"] = user.user_image
        comment["user"]["path"] = "/profile/#{user.id}/#{user_profile.display_name}"
        t["comments"] <<  comment
      end
      t["data"] = {}
      unless  params[:current_user].blank?
        likes = Vote.where("votable_id = #{params[:item_id]} and votable_type = 'Tweet' and voter_type = 'User' and voter_id = #{params[:current_user]}")
        t["data"]["likes"] = 0
        t["data"]["dislikes"] = 0
        unless likes.blank?
          if likes.vote_flag == 't'
            t["data"]["likes"] = 1
            t["data"]["dislikes"] = 0
          elsif likes.vote_flag == 'f'
            t["data"]["likes"] = 0
            t["data"]["dislikes"] = 1
          end
        end
      end
      t["flag"] = params[:flag]
      item = []
      item << t
      render :json => item

    when 'topten'

    end 
  end
  
  def movie_action
    unless params[:user_id].blank?
     current_user = User.find(params[:user_id].to_i)
     if !current_user.blank?
      case params[:actions]
      when 'wanttosee'
        @count = WantToSee.check_user(current_user.id,params[:item_id])
        if @count.blank?
          @want_to_see = WantToSee.new
          @want_to_see.user_id = current_user.id
          @want_to_see.movie_id = params[:item_id]
          @want_to_see.is_want_to_see = true
          @want_to_see.save
          @user_badge =  UserBadge.new
          @user_badge.add_badge_points(current_user.id)
        else
          if !@count.is_want_to_see 
            @count.update_attribute('is_want_to_see', true)
            @user_badge =  UserBadge.new
            @user_badge.add_badge_points(current_user.id)
          end
        end
        render :json => {:status => 'success', :item_type =>params[:item_type],"item_id" => params[:item_id], :action => params['actions']}
      when 'notanymore'
        @count = WantToSee.check_user(current_user.id,params[:item_id])
        if @count.blank?
          @want_to_see = WantToSee.new
          @want_to_see.user_id = params[:user_id]
          @want_to_see.movie_id = params[:item_id]
          @want_to_see.is_want_to_see = false
          @want_to_see.save
          @user_badge =  UserBadge.new
          @user_badge.add_badge_points(current_user.id)
        else
          if @count.is_want_to_see
            @count.update_attribute('is_want_to_see' ,false)
            @user_badge =  UserBadge.new
            @user_badge.add_badge_points(current_user.id)
          end
        end
        render :json => {:status => 'success', :item_type =>params[:item_type],"item_id" => params[:item_id], :action => params['actions']}
      when 'likes'
        if params[:item_type] == 'movies'
          @movie = Movie.find_by_id(params[:item_id])
          @review = Review.where(:user_id => params[:user_id], :movie_id => params[:item_id])
          if @review.size > 0
            @review = Review.where(:user_id => params[:user_id], :movie_id => params[:item_id]).first
            if @review.rating != 4
              @review.update_attributes(:rating =>  4)
            end
          else
            @movie.reviews.create({:rating=> 4, :user_id => current_user.id})
          end
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'video'
          @video = Video.find_by_id(params[:item_id])
          @video.vote :voter =>current_user, :vote => 'like'
          @video.taggings.each do |tagging|
            if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?
              if tagging.tagger_type == 'Movie'
                @object = Movie.find_by_id(tagging.tagger_id)
                @path = 'movies'
              elsif tagging.tagger_type == 'Celebrity'
                @object = Celebrity.find_by_id(tagging.tagger_id)
                @path = 'stars'
              end
            end
          end
          Video.log_video_activity(current_user,@video,'Likes' , @object, @path)
          render :text => 'success'
        elsif params[:item_type] == 'poster'
          @poster = Poster.find_by_id(params[:item_id])
          @poster.vote :voter =>current_user, :vote => 'like'
          @poster.taggings.each do |tagging|
            if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?
              if tagging.tagger_type == 'Movie'
                @object = Movie.find_by_id(tagging.tagger_id)
                @path = 'movies'
              elsif tagging.tagger_type == 'Celebrity'
                @object = Celebrity.find_by_id(tagging.tagger_id)
                @path = 'stars'
              end
            end
          end
          Poster.log_poster_activity(current_user,@poster, 'Likes', @object, @path)
          render :text => 'success'
        elsif params[:item_type] == 'news'
          @news = Feed.find_by_id(params[:item_id])
          @news.vote :voter =>current_user, :vote => 'like'
          render :text => 'success'
        elsif params[:item_type] == 'critic'
          @critic = CriticsReview.find(params[:item_id])
          @critic.vote :voter =>current_user, :vote => 'like'
          render :text => 'success'
        elsif params[:item_type] == 'review'
          @review = Review.find_by_id(params[:item_id])
          @review.vote :voter =>current_user, :vote => 'like'
          render :text => 'success'
        end
      when 'dislikes'
        if params[:item_type] == 'movies'
          @movie = Movie.find_by_id(params[:item_id])
          @review = Review.where(:user_id => params[:user_id], :movie_id => params[:item_id])
          if @review.size > 0
            @review = Review.where(:user_id => params[:user_id], :movie_id => params[:item_id]).first
            if @review.rating != 2
              @review.update_attributes(:rating =>  2)
            end
          else
            @movie.reviews.create({:rating=> 2, :user_id => current_user.id})
          end
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'video'
          cast = []
          @video = Video.find_by_id(params[:item_id])
          @video.vote :voter =>current_user, :vote => 'bad'
          @video.taggings.each do |tagging|
            if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?
              if tagging.tagger_type == 'Movie'
                #cast["id"] = tagging.tagger_id
                @object = Movie.find_by_id(tagging.tagger_id)
                @path = 'movies'
              elsif tagging.tagger_type == 'Celebrity'
                #cast["id"] = tagging.tagger_id
                @object = Celebrity.find_by_id(tagging.tagger_id)
                @path = 'stars'
              end
            end
          end
          Video.log_video_activity(current_user,@video,'Dislikes' , @object, @path)
          render :text => 'success'
        elsif params[:item_type] == 'poster'
          @poster = Poster.find_by_id(params[:item_id])
          @poster.vote :voter =>current_user, :vote => 'bad'
          @poster.taggings.each do |tagging|
            if tagging.tagger_type != 'Profile' and !tagging.tagger_id.blank?
              if tagging.tagger_type == 'Movie'
                @object = Movie.find_by_id(tagging.tagger_id)
                @path = 'movies'
              elsif tagging.tagger_type == 'Celebrity'
                @object = Celebrity.find_by_id(tagging.tagger_id)
                @path = 'stars'
              end
            end
          end
          Poster.log_poster_activity(current_user,@poster, 'Dislikes', @object, @path)
          render :text => 'success'
        elsif params[:item_type] == 'news'
          @news = Feed.find_by_id(params[:item_id])
          @news.vote :voter =>current_user, :vote => 'bad'
          render :text => 'success'
        elsif params[:item_type] == 'critic'
          @critic = CriticsReview.find(params[:item_id])
          @critic.vote :voter =>current_user, :vote => 'bad'
          render :text => 'success'
        elsif params[:item_type] == 'review'
          @review = Review.find_by_id(params[:item_id])
          @review.vote :voter =>current_user, :vote => 'bad'
          render :text => 'success'
        end
      when 'fan'
        @count = Fan.check_user(current_user.id,params[:item_id])
        if @count.blank?
          @fan = Fan.new
          @fan.user_id = current_user.id
          @fan.celebrity_id = params[:item_id]
          @fan.is_fan = true
          @fan.save
          @user_badge =  UserBadge.new
          @user_badge.add_badge_points(current_user.id,'fan', params[:item_id])
        else
          if !@count.is_fan
            @count.update_attribute('is_fan', true)
            @user_badge =  UserBadge.new
            @user_badge.add_badge_points(current_user.id,'fan', params[:item_id])
          end
        end
        render :json => {:status => 'success', :item_type =>params[:item_type],"item_id" => params[:item_id], :action => params['actions']}
      when 'unfan'
        @count = Fan.check_user(current_user.id,params[:item_id])
        if @count.blank?
          @fan = Fan.new
          @fan.user_id = current_user.id
          @fan.celebrity_id = params[:item_id]
          @fan.is_fan = false
          @fan.save
          @user_badge =  UserBadge.new
          @user_badge.add_badge_points(current_user.id,'unfan', celeb_id)
        else
           if @count.is_fan
             @count.update_attribute('is_fan', false)
             @user_badge =  UserBadge.new
             @user_badge.add_badge_points(current_user.id,'unfan', celeb_id)
           end
        end
        render :json => {:status => 'success', :item_type =>params[:item_type],"item_id" => params[:item_id], :action => params['actions']}
      when 'discussion'
        ref_type = params[:item_type] == 'star' ? 'celebrity' : 'movie'
        @refer = ref_type.capitalize.constantize.find_by_id(params[:item_id])
        @discussion = Discussion.new({:user_id => current_user.id,:question => params[:comment]})
        if @discussion.save
          refer_tag = Tag.find_by_name(@refer.name)
          if refer_tag.blank?
            refer_tag = Tag.create({:id => Tag.last.id + 1, :name=>@refer.name})
          end
          Tagging.create(:tag_id => refer_tag.id, :taggable_id => @discussion.id,:taggable_type => "Discussion",:tagger_id => @refer.id, :tagger_type =>  @refer.class.to_s,:context => "tags")
        end
        render :json => {:status => 'success'}
      when 'comment'
        if params[:item_type] == 'movie'
          @review = Review.where(:user_id => params[:user_id], :movie_id => params[:item_id]).first
          if @review.description != params[:comment]
            @review.update_attributes(:description =>  params[:comment])
          end
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'video'
          video = Video.find_by_id(params[:item_id])
          @comment = video.comments.new({:comment =>  params[:comment],:user_id => current_user.id})
          @comment.save
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'poster'
          poster = Poster.find_by_id(params[:item_id])
          @comment = poster.comments.new({:comment =>  params[:comment],:user_id => current_user.id})
          @comment.save
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'news'
          feed = Feed.find_by_id(params[:item_id])
          @comment = feed.comments.new({:comment =>  params[:comment],:user_id => current_user.id})
          @comment.save
          render :json => {:status => 'success'}
        elsif params[:item_type] == 'celebtweet'
          tweet = CelebTweet.find(params[:item_id])
          @comment = tweet.comments.new({:comment =>  params[:comment],:user_id => current_user.id})
          @comment.save
          render :json => {:status => 'success'}
        end
      else
        render :json => {:status => 'failure'}
      end
     else
      render :json => {:status => 'failure'}
     end
    else
      render :json => {:status => 'failure'}
    end
  end
  def record_not_found
    respond_to do |format|
      format.json  { render :json => {:status => 'failure'} }
      format.xml  { render :xml => {:status => 'failure'} }
    end
  end
end
