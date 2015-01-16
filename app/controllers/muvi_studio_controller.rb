class MuviStudioController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def index
     posters = []
     videos = []
     youtube = []
    if params[:type] == 'movie'
      movie = Movie.find_using_id(params[:id]).first
      poster_list = Poster.get_poster(movie.id, "Movie", "Poster")
      video_list =  Video.get_video(movie.id, "Movie", "Video")
      top_videos = Video.get_top_score_record(video_list)
      top_posters = Video.get_top_score_record(poster_list)
      if params[:act] == 'details'
        casts = []
        cast_crew = movie.movie_casts.includes(:celebrity)
        poster_list.each do |poster|
          posters << {:direct_path => "movies/#{movie.permalink}/poster/#{poster.id}", :site_path => "posters/movie/#{movie.permalink}/#{poster.id}"}
        end  
        video_list.each do |video|
         unless video.video_remote_url.blank?
           youtube << video.video_remote_url
         end        
         videos << {:direct_path => "movies/#{movie.permalink}/video/#{video.id}", :site_path => "videos/movie/#{movie.permalink}/#{video.id}"}
        end
        cast_crew.each  do |cast|
         casts << {:cast_type => cast.cast_type, :path => celebrity_path(cast.celebrity)}
        end
        json_data = {:id => movie.id, :name=> movie.name, :path => movie_path(movie), :wiki_path => movie.wiki_link, :facebook_path => movie.fbpage_id, :videos => videos, :youtube => youtube ,:posters => posters, :casts => casts} 
      elsif params[:act] == 'muvimeter'
        json_data = {:id => movie.id, :name=> movie.name, :muvimeter => movie.muvimeter}
      elsif params[:act] == 'engagement'
        json_data = {:id => movie.id, :name=> movie.name, :engagement => (top_videos.size+top_posters.size+movie.discussions.size)}
      elsif params[:act] == 'press'
        news_count = 0
        casts = movie.movie_casts.where("cast_type = 'actor'").limit(2)
        casts.each do |cast|
          news_count += News.get_news(cast.celebrity_id, 'Celebrity').size
        end
        json_data = {:id => movie.id, :name=> movie.name, :press => News.get_news(movie.id, "Movie").size.to_i + news_count}
      end
    elsif params[:type] == 'star'
      star = Celebrity.find_using_id(params[:id]).first
      poster_list = Poster.get_poster(star.id, "Celebrity", "Poster")
      video_list =  Video.get_video(star.id, "Celebrity", "Video")
      top_videos = Video.get_top_score_record(video_list)
      top_posters = Video.get_top_score_record(poster_list)
      if params[:act] == 'details'
        movies = []
        upcoming_movies = Celebrity.upcoming_movies(star)
        full_filmography = Celebrity.full_filmography(star)
        poster_list.each do |poster|
          posters << {:direct_path => "movies/#{star.permalink}/poster/#{poster.id}", :site_path => "posters/movie/#{star.permalink}/#{poster.id}"}
        end
        video_list.each do |video|
          videos << {:direct_path => "movies/#{star.permalink}/video/#{video.id}", :site_path => "videos/movie/#{star.permalink}/#{video.id}"}
        end
        upcoming_movies.each do |movie|
          movies << {:name => movie.name, :path => movie_path(movie)}
        end
        full_filmography.each  do |movie|
          movies << {:name => movie.name, :path => movie_path(movie)}
        end
        json_data = {:id => star.id, :name => star.name, :path => celebrity_path(star), :videos => videos, :posters => posters, :movies => movies} 
      elsif params[:act] == 'popularity'
        json_data = {:id => star.id, :name=> star.name, :path => celebrity_path(star), :popularity => star.popularity.to_i}
      elsif params[:act] == 'engagement'
        json_data = {:id => star.id, :name=> star.name, :engagement => (top_videos.size+top_posters.size+star.discussions.size)}
      elsif params[:act] == 'press'
        json_data = {:id => star.id, :name=> star.name, :press => News.get_news(star.id, "Celebrity").size}
      end
    end
    render :json => json_data
  end
  def post
   if params[:content_type] == 'Poster'
     movie_poster_path = params[:content_path]
     movie_id = params[:movie_id];
     movie = Movie.find_by_id(movie_id)
     movie_name = movie.name
     @poster = Poster.new(:poster_remote_url => movie_poster_path, :name => params[:name], :rank => 1)
     @poster.save
     p = Poster.where("id = #{@poster.id}").first

     p.crop_x = 0
     p.crop_y = 0
     p.crop_h = 210
     p.crop_w = 210

     p.update_attributes(p)
  
   
     tagname = Tag.where("lower(name) = ?", movie_name.downcase.strip)
     if tagname.blank?
       @tag = Tag.new
       @tag.id = Tag.last.id + 1
       @tag.name = movie_name
       @tag.save
       @tag_id = @tag.id
     else
       @tag_id = tagname[0].id
     end
     ActiveRecord::Base.connection.execute("SELECT setval('tags_id_seq',#{@tag_id})")
     @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => movie_id,:tagger_type => 'Movie', :context =>'tags')
     @tagging.save
     if !params[:content_tag].blank?
       tag_id = 331
       if params[:content_tag] == 'still'
         tag_id = 5349
       elsif params[:content_tag] == 'ontheset'
         tag_id = 5347
       end
       @tagging = Tagging.new(:tag_id => tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => params[:content_tag], :context =>'tags')
       @tagging.save
     end
   elsif  params[:content_type] == 'Video'
     movie_video_path  = params[:content_path]
     movie_id = params[:movie_id];
     movie = Movie.find_by_id(movie_id)
     movie_name = movie.name
     source_url = movie_video_path
     @video = Video.new(:video_remote_url => source_url ,:name => params[:name], :rank => 1)
     @video.save
     unless source_url["youtu"] == 'youtu'
       @video.video_remote_url = ''
       @video.save
       Video.create_thumbnail_remote(@video.id, source_url.to_s.sub("http://#{AWS::S3::DEFAULT_HOST}","s3:/"))
     end
     tagname = Tag.where("lower(name) = ?", movie_name.downcase.strip)
     if tagname.blank?
       @tag = Tag.new
       @tag.id = Tag.last.id + 1
       @tag.name = movie_name
       @tag.save
       @tag_id = @tag.id
     else
       @tag_id = tagname[0].id
     end
     ActiveRecord::Base.connection.execute("SELECT setval('tags_id_seq',#{@tag_id})")
     @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @video.id, :taggable_type => 'Video', :tagger_id => movie_id,:tagger_type => 'Movie', :context =>'tags')
     @tagging.save
     if !params[:content_tag].blank?
       @tagging = Tagging.new(:tag_id => 331, :taggable_id => @video.id, :taggable_type => 'Video', :tagger_type => params[:content_tag], :context =>'tags')
       @tagging.save
     end
   end
   render :json => params
  end

end
