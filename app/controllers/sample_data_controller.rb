class SampleDataController < ApplicationController
  require 'json'
  include ActionView::Helpers::DateHelper
  skip_before_filter :authenticate_user!, :verify_authenticity_token


  def sample_movie_details
    @movie_final = []
    m = Movie.find_by_name(params[:name])
    
    @final = []
    #mov.each do |m|
      @actors = []
      @cast_detail = []
      m.movie_casts.includes(:celebrity).each do |cast|
        if cast.cast_type == 'actor'
          celeb = {}
          celeb["celeb_id"] = cast.celebrity_id
          celeb["celeb_name"] = cast.celebrity.name
          celeb["role_name"] = cast.role_name
          celeb["celeb_image"] = "#{POSTER_URL}#{cast.celebrity.thumb_image}"
          @cast_detail << celeb
        end
      end
      m.movie_casts.each do |cast|
        case cast.cast_type
          when 'actor' then @actors << cast
          if @actors.size == 2
            break
          end
        end
      end
      actor_name = ''
      @actors.each do |act|
        unless act.celebrity.blank?
          if actor_name.blank?
            actor_name = act.celebrity.name
          else
            actor_name = actor_name + ", "+ act.celebrity.name
          end
        end
      end
      
      thumb_image = "#{POSTER_URL}#{m.banner_image_medium}"
      banner_image = "#{POSTER_URL}#{m.banner_image}"
      cropped_image = "#{POSTER_URL}#{m.crop_full_image}"

      discussions = []
      m.discussions.reverse.first(3).each do |discussion|
        comment = {}
        comment["id"] = discussion.id
        comment["question"] = discussion.question
        #comment["description"] = discussion.description
        comment["user"] = {}
        comment["user_id"] = discussion.user_id
        user = User.find_by_id(discussion.user_id)
        if user
          user_profile = UserProfile.find_by_user_id(discussion.user_id)
          comment["time_diff"] = distance_of_time_in_words(Time.now,discussion.created_at) + " ago"
          comment["user_name"] = user_profile.display_name
          comment["user_image"] = "#{POSTER_URL}#{user.user_image}"
          discussions <<  comment
        end
      end
      
      unless m.genre.blank?
        genre = m.genre
      else
        genre = ""
      end

      unless m.release_date.blank?
        release_date = m.release_date.strftime('%b %d, %Y')
      else
        release_date = ""
      end


      muvimeter = ""
      unless m.muvimeter.blank?
        if m.muvimeter.to_i >= 60
          muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding:0px 3px 5px 2px; width: 77px;float:left;margin-right:2px'>  <div style='width:#{m.muvimeter}%; background:url(\"http://www.muvi.com/images/G-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.muvimeter}%</div>"

        elsif m.muvimeter.to_i < 60
          muvimeter = "<div style='background-color: #D8D8D8; border: 1px solid #BECBD4;border-radius: 6px;-moz-border-radius:6px; -webkit-border-radius:6px; height: 19px; padding: 0px 3px 5px 2px; width: 77px;float:left;margin-right:3px'><div style='width:#{m.muvimeter}%; background:url(\"http://www.muvi.com/images/R-RatingBar.jpg\") repeat-x scroll 0 1px transparent; border-radius:6px;-moz-border-radius:6px; -webkit-border-radius:6px; height:17px;'>&nbsp;</div></div><div style='float:left;'>#{m.muvimeter}%</div>"

        end
      end

      
      if params[:user_id]
        logged_in = 1
      else
        logged_in = 0
      end


 
      ################ CRITICS REVIEW STARTS ###############

      movie_critics_review = []
      profile_img = ""
      profile_image = ""
      profile_name = ""
      review_description = ""

      @critics_review = CriticsReview.where("movie_id = ?", m.id).limit(10).published.latest.search({:movie_id_eq => m.id})
      unless @critics_review.blank?
        @critics_review.each do |critics_review|
          fc = critics_review.film_critic
          unless fc.blank?
            unless fc.profile_image.blank?
              unless fc.thumbnail_image_file_name.blank?
                profile_img = "#{POSTER_URL}/system/thumbnail_images/#{fc.id}/thumb/#{fc.thumbnail_image_file_name.gsub(" ", "%20")}"
              else
                profile_img = "#{POSTER_URL}/images/no-profile.png"
              end
            else
              profile_image = "#{POSTER_URL}/images/no-profile.png"
            end
          end
          review_description = critics_review.summary.slice!(0, 60) unless critics_review.summary.blank?
          movie_critics_review << {:profile_image => profile_img, :profile_name => profile_name, :review_description => review_description}
        end
      end
      ################ CRITICS REVIEW ENDS ###############


      user_like_status = ""
      user_dislike_status = ""
      like_reviews = []
      m.reviews.each do |review|
        if review.rating > 3
          if review.user_id.to_s == params[:user_id]
            user_like_status = true
          end
          rev = {}
          rev[:user_id] = review.user_id
          rev[:user_name] = review.user.display_name
          if  review.user.user_image =~ /http:/
            rev[:user_image] = "#{review.user.user_image}"
          else
            rev[:user_image] = "#{POSTER_URL}#{review.user.user_image}"
          end
          like_reviews << rev
        else
          if review.user_id.to_s == params[:user_id]
            user_dislike_status = true
          end
        end
      end

      poster_list = Poster.get_poster(m.id, "Movie", "Poster")
      posters = []
      poster_list.each do |poster|
        pic = {}
        pic[:id] = poster.id
        pic[:name] = poster.name
        pic[:path] = "#{POSTER_URL}/system/posters/#{poster.id}/medium/#{poster.poster_file_name.gsub(" ", "%20")}"
        posters << pic
      end

	  
      video_list =  Video.get_video(m.id, "Movie", "Video")
      videos = []
      video_list.each do |video|
        vid = {}
        vid[:id] = video.id
        vid[:name] = video.name
        unless video.video_remote_url.blank?
          video_id_arr = video.video_remote_url.split("/")
          video_id = video_id_arr[video_id_arr.size.to_i - 1]

          vid[:path] = "http://img.youtube.com/vi/#{video_id}/1.jpg"
          vid[:link] = video.video_remote_url
        else
          vid[:path] = "#{POSTER_URL}/system/trailer_thumbnails/#{video.id}/1.jpg"
          vid[:link] = "#{POSTER_URL}/system/trailers/#{video.id}/original/#{video.trailer_file_name}"
        end
        videos << vid
      end

      @movie_final << {:id => m.id, :name => m.name, :permalink => m.permalink, :thumb_image => "#{thumb_image}", :banner_image => "#{banner_image}", :cropped_image => "#{cropped_image}", :actor => actor_name, :muvimeter =>  muvimeter.html_safe, :tweet_percent => m.tweet_percent.to_i, :release_date => release_date, :discussions => discussions,:genre => genre,:cast_detail => @cast_detail,:like_reviews => like_reviews,:user_dislike_status=>user_dislike_status,:user_like_status=>user_like_status, :critics_review => movie_critics_review, :posters => posters, :videos => videos}
    #end
    #render :json => @movie_final.to_json
    render :json => JSON.pretty_generate(@movie_final)
  end

end
