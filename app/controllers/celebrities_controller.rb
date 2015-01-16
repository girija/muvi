class CelebritiesController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :msn_redirect, :only => [:index, :show]

  #layout 'website'
  layout:check

  require 'will_paginate/array'

  def index
    render :template => "/home_display/index" , :locals => {:type => "star"}
  end

  def load_star_page
    page_no = DisplayHelper.get_page_number("stars", params, cookies)
    if page_no.blank?
      page_no = 21
    end

    @arr = DisplayHelper.get_result('star_page_cache', page_no, "star")
    @arr.sort!{|a,b| (a.id) <=> (b.id)}
    @result = @arr.paginate(:page => params[:page], :per_page => PER_PAGE)

    #render :template => "/home_display/index"
    unless params[:page].blank?
      respond_to do |format|
        format.js {}
      end
    else
      render :partial => "/home_display/load_language"
    end

  end

  def show
    if request.fullpath =~ /celebrities/
      redirect_to "http://#{request.env["HTTP_HOST"].gsub('celebrities','stars')}#{request.fullpath.gsub('celebrities','stars')}"
      return
    end
    @celebrity = Celebrity.find_using_id(params[:id]).first
  end

  def show_old
    if request.fullpath =~ /celebrities/
      redirect_to "http://#{request.env["HTTP_HOST"].gsub('celebrities','stars')}#{request.fullpath.gsub('celebrities','stars')}"
      return
    end
    @celebrity = Celebrity.find_using_id(params[:id]).first  
    #@poster_list = Poster.get_poster(@celebrity.id, "Celebrity", "Poster")
    #@video_list =  Video.get_video(@celebrity.id, "Celebrity", "Video")
    unless params[:full_filmography].blank?
      render :partial => "shared/full_filmography"
    end
    unless params[:costar].blank?
      @costar = Celebrity.find_using_id(params[:costar]).first
    end
    unless @celebrity.blank?
      @poster_list = Poster.get_poster(@celebrity.id, "Celebrity", "Poster")
      @video_list =  Video.get_video(@celebrity.id, "Celebrity", "Video")
      @tweets = @celebrity.celebrity_tweets.order("created_at desc")
      if params[:engage] == "1"
        if params[:filter] == "Star"
          @celeb_tweet = @celebrity.celebrity_tweets.limit(5)
          @engage_items = (@celeb_tweet.sort_by &:created_at).reverse
        else
          @top_videos = Video.get_top_score_record(@video_list)
          @top_posters = Video.get_top_score_record(@poster_list)
          @celeb_tweet = @celebrity.celebrity_tweets.limit(5)
          #@engage_items = @celeb_tweet+((@top_videos+@top_posters).sort_by &:score).reverse[0 .. 9]+@celebrity.discussions[0 .. 4]
          @engage_items = ((@celeb_tweet + @top_videos+@top_posters+@celebrity.discussions).sort_by &:created_at).reverse
        end
        render :partial => "shared/engage"
      end
      if !params[:extra_arg].nil? && params[:extra_arg] == "news"
        @news = Tagging.where("tagger_type = 'Celebrity' and taggable_type='Feed'").find(:all, :conditions => ["tagger_id = ?", @celebrity.id], :order => ["created_at desc"])
        if !params[:ajax].nil? && params[:ajax] == "1"
          render :partial => "/shared/all_news"
          return
        end
      else
        @news = Tagging.where("tagger_type = 'Celebrity' and taggable_type='Feed'").find(:all, :conditions => ["tagger_id = ?", @celebrity.id], :order => ["created_at desc"], :limit => ["3"])

      end

      @total_fan = Celebrity.total_fan(@celebrity.id)
      unless current_user.blank?
        @celebrity_fans_1 = Celebrity.get_fans_connection(current_user,@celebrity.id, true)
        @celebrity_fans = @celebrity_fans_1.collect {|x| x.user_id}.uniq

        @not_celebrity_fans_1 = Celebrity.get_fans_connection(current_user,@celebrity.id, false)
        @not_celebrity_fans = @not_celebrity_fans_1.collect {|x| x.user_id}.uniq

        @fan = Celebrity.fan_from_friends(@celebrity, current_user)
        @count_fan = Fan.find(:all,
              :select => ["id, is_fan"],
              :conditions =>["user_id = ? AND celebrity_id = ?", current_user.id,@celebrity.id])
      else
        @celebrity_fans_1 = @celebrity.fans
        @celebrity_fans = @celebrity_fans_1.collect {|x| x.user_id}.uniq

        @not_celebrity_fans_1 = @celebrity.not_fans
        @not_celebrity_fans = @not_celebrity_fans_1.collect {|x| x.user_id}.uniq
      end
      @top_costars = Celebrity.get_top_costars(@celebrity)
      @top_crews = Celebrity.get_top_crews(@celebrity)
    else
      puts "permalink not found"
      redirect_to "/404.html"
      return
    end
    unless params[:video_id].blank?
      video = Video.find_by_id(params[:video_id])
      unless video.blank?
        unless video.video_remote_url.blank?
          @video_type = "external"
          video_id_arr = video.video_remote_url.split("/")
          @video_id = video_id_arr[video_id_arr.size.to_i - 1]
        else
          @video_type = "internal"
        end
      end
    end
    #render :layout => "home"

  end 
  def popup
    @celebrity = Celebrity.find_by_id(params[:id])
    render :partial => 'shared/celebrity_badge'
  end

  def show_cangratulations
      render :partial => 'shared/show_cangratulations'
  end
  def follow
    celeb = Celebrity.find(params["list_id"])
    user = User.find(params["user_id"])
    user.follow(celeb)

    unless params[:notification_id].blank?
      #ac = AllActivity.find(params[:activity_id]) unless params[:activity_id].blank?
      #ac.update_attribute('viewed', 't') unless ac.blank?

      AllNotification.find(:first, :conditions => ["id = #{params[:notification_id]} and feed_user = #{current_user.id}"]).destroy
    end

    AllActivity.create_next_movie_notification(user, params["list_id"])
    AllActivity.create_follow_activity(celeb, user, "celebrity")

    render :partial => 'followers', :locals => {:@tagged => celeb}
  end

  def get_top
    @celebrity = Celebrity.find(params[:celeb_id])
    @top_rated_movies = ApplicationHelper.celeb_top_rated_movies(@celebrity)
    render :partial => "get_top"
  end

  def get_upcoming
    @celebrity = Celebrity.find(params[:celeb_id])
    @upcoming_movies = ApplicationHelper.celeb_upcoming_movies(@celebrity)
    render :partial => "get_upcoming"
  end

  def get_play
    @celebrity = Celebrity.find(params[:celeb_id])
    @play_movies = ApplicationHelper.celeb_play_movies(@celebrity)
    render :partial => "get_play"
  end

  def get_all_movies
    celebrity = Celebrity.find(params[:celeb_id])
    @page = params[:page]
    @all_movies = celebrity.movie_casts.find(:all, :select => ["movie_id"], :conditions => ["movie_id IS NOT NULL and films.id IS NOT NULL  and films.release_date <= NOW()"],:joins => ["LEFT JOIN films on films.id = movie_casts.movie_id"], :group => ["movie_id,films.release_date"], :order => ["films.release_date desc"]).paginate(:page => @page, :per_page => 1)
    render :partial => "get_all_movies"

    #respond_to do |format|
    #    format.js
    #end
  end



  def autocomplete
    celebrity_names = Celebrity.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |user|
      { "label" => user.name, "value" => user.id }
    end
    render :json => celebrity_names.to_json
  end

end

