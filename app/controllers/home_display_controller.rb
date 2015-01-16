class HomeDisplayController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :msn_redirect, :only => [:index, :released, :upcoming]

  layout:check
  require 'rest_client'

  def index
    render :template => "/home_display/index" , :locals => {:type => "movies"}
  end

  def load_home_page
    page_no = DisplayHelper.get_page_number('movies', params, cookies)
    if page_no.blank?
      page_no = 20
    end

    @arr = DisplayHelper.get_result('home_page_cache', page_no, "movies")
    @arr.sort!{|a,b| (b.score) <=> (a.score)}
    @result = @arr.paginate(:page => params[:page], :per_page => PER_PAGE)
    #@result.sort!{|a,b| (b.score) <=> (a.score)}

    unless params[:page].blank?
      respond_to do |format|
        format.js {}
      end
    else
      render :partial => "load_language"
    end
  end

  def refresh_comment
    @total_block = []
    user = ""
    unless current_user.blank?
      user = current_user.id
    else
      user = ""
    end

    begin
      unless params[:flag_detail].blank?
        flag_detail = params[:flag_detail].gsub(" ", "%20")
      else
        flag_detail = ""
      end

      @block = ActiveSupport::JSON.decode(RestClient.get "#{SERVICE_URL}/muvi/#{params[:type]}/#{params[:id]}?flag=#{flag_detail}&current_user=#{user}", :content_type => :json)
      @total_block << @block
    rescue Exception => exc
      logger.error("Message for the log file #{exc.message}")
    end
    render :partial => "index"
  end

   def reload_for_engage
    @total_block = []
    user = ""
    unless current_user.blank?
      user = current_user.id
    else
      user = ""
    end

    begin
      unless params[:flag_detail].blank?
        flag_detail = params[:flag_detail].gsub(" ", "%20")
      else
        flag_detail = ""
      end

      @block = ActiveSupport::JSON.decode(RestClient.get "#{SERVICE_URL}/muvi/#{params[:type]}/#{params[:id]}?flag=#{flag_detail}&current_user=#{user}&reload=1", :content_type => :json)
      @total_block << @block
    rescue Exception => exc
      logger.error("Message for the log file #{exc.message}")
    end
    render :partial => "index"
  end


  def released
    render :template => "/home_display/index" , :locals => {:type => "released"}
  end

  def load_released
    page_no = DisplayHelper.get_page_number("released", params, cookies)
    if page_no.blank?
      page_no = 22
    end

    @with_release_date = []
    @blank_release_date = []
    @new_arr = []
    @arr = DisplayHelper.get_result('released_page_cache', page_no, "released")
    @arr.each do |ar|
      if !ar.release_date.blank?
        @with_release_date << ar
      else
        @blank_release_date << ar
      end
    end
    @with_release_date.sort!{|a,b| (b.release_date) <=> (a.release_date)}
    @new_arr = @with_release_date | @blank_release_date

    @result = @new_arr.paginate(:page => params[:page], :per_page => PER_PAGE)

    #render :template => "/home_display/index"
    unless params[:page].blank?
      respond_to do |format|
        format.js {}
      end
    else
      render :partial => "load_language"
    end
  end

  def upcoming
    render :template => "/home_display/index" , :locals => {:type => "upcoming"}
  end

  def load_upcoming
    page_no = DisplayHelper.get_page_number("upcoming", params, cookies)
    if page_no.blank?
      page_no = 23
    end

    @with_release_date = []
    @blank_release_date = []
    @new_arr = []

    @arr = DisplayHelper.get_result('upcoming_page_cache', page_no, "upcoming")

    @arr.each do |ar|
      if !ar.release_date.blank?
        @with_release_date << ar
      else
        @blank_release_date << ar
      end
    end
    @with_release_date.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}
    @new_arr = @with_release_date  | @blank_release_date
    #@arr.sort!{|a,b| (a.release_date) <=> (b.release_date)}

    @result = @new_arr.paginate(:page => params[:page], :per_page => PER_PAGE)

    #render :template => "/home_display/index"
    unless params[:page].blank?
      respond_to do |format|
        format.js {}
      end
    else
      render :partial => "load_language"
    end
  end

  def fetch_movie(movie_type)
    @temp_movie = []
    @temp_blank_release = []

    if movie_type == "released"
      @list = Rails.cache.fetch('released_page_cache'){HomePageSetting.find(:all, :conditions => ["subject_type = 'Movie' and page_no = 12"], :order => ["id asc"])}
    elsif movie_type == "upcoming"
      @list = Rails.cache.fetch('upcoming_page_cache'){HomePageSetting.find(:all, :conditions => ["subject_type = 'Movie' and page_no = 13", :order => ["id asc"]])}
    end


    unless @list.blank?
      @list.each do |list|
        m = Movie.select("id, release_date").find(list.subject_id)

        # Create corresponsding array
        if movie_type == "upcoming"
          if !m.release_date.blank? and m.release_date > Date.today
            @temp_movie << m
          elsif m.release_date.blank?
            @temp_blank_release << m
          end
        else
          if !m.release_date.blank? and m.release_date < Date.today
            @temp_movie << m
          end
        end
        ####
      end
    end
    @temp_movie.uniq
    unless @temp_movie.blank?
      @total_movie_block = []
      user = ""
      unless current_user.blank?
        user = current_user.id
      else
        user = ""
      end
      @temp_movie.sort!{|a,b| (a.release_date).strftime("%Y-%m-%d") <=> (b.release_date).strftime("%Y-%m-%d")}

      #For upcoming movie, add the blank release date movies to the array
      if movie_type == "upcoming"
        @temp_movie = @temp_movie | @temp_blank_release
        @temp_movie.uniq
      end
      #

      @temp_movie.each do |mov|
        @block = ActiveSupport::JSON.decode(RestClient.get "#{SERVICE_URL}/muvi/movie/#{mov.id}?current_user=#{user}", :content_type => :json)
        @total_movie_block << @block
      end
    end
    render :template => "/home_display/index"
  end

  def load_language
    cache = ""
    sort_by = ""
    page_no = DisplayHelper.get_page_number(params[:type], params, cookies)
    
    if page_no.blank?
      if params[:type] == "movies"
        page_no = 10
      elsif params[:type] == "stars"
        page_no = 11
      elsif params[:type] == "released"
        page_no = 12
      elsif params[:type] == "upcoming"
        page_no = 13
      elsif params[:type] == "trailers"
        page_no = 14
      elsif params[:type] == "picture"
        page_no = 16
      end
    end

    if params[:type] == "movies"
      cache = 'home_page_cache'

    elsif params[:type] == "stars"
      cache = 'star_page_cache'

    elsif params[:type] == 'released'
      cache = 'released_page_cache'

    elsif params[:type] == 'upcoming'
      cache = 'upconing_page_cache'

    elsif params[:type] == 'trailers'
      cache = 'trailer_page_cache'
    elsif params[:type] == 'picture'
      cache = 'picture_page_cache'
    end

    @arr = DisplayHelper.get_result(cache, page_no, params[:type])

    if params[:type] == "movies"
      @arr.sort!{|a,b| (b.score) <=> (a.score)}

    elsif params[:type] == "stars"
      @arr.sort!{|a,b| (a.id) <=> (b.id)}

    elsif params[:type] == 'released'
      #@arr.sort!{|a,b| (b.release_date).strftime("%Y-%m-%d") <=> (a.release_date).strftime("%Y-%m-%d")}
      @with_release_date = []
      @blank_release_date = []
      @new_arr = []
  
      @arr.each do |ar|
        if !ar.release_date.blank?
          @with_release_date << ar
        else
          @blank_release_date << ar
        end
      end
      @with_release_date.sort!{|a,b| (b.release_date).strftime("%Y-%m-%d") <=> (a.release_date).strftime("%Y-%m-%d")}
      @new_arr = @with_release_date | @blank_release_date 
      @new_arr.uniq

    elsif params[:type] == 'upcoming'
      #@arr.sort!{|a,b| (a.release_date) <=> (b.release_date)}
      @with_release_date = []
      @blank_release_date = []
      @new_arr = []

      @arr.each do |ar|
        if !ar.release_date.blank?
          @with_release_date << ar
        else
          @blank_release_date << ar
        end
      end
      @with_release_date.sort!{|a,b| (a.release_date) <=> (b.release_date)}
      @new_arr = @with_release_date | @blank_release_date
      @new_arr.uniq

    elsif params[:type] == 'trailers'
      begin
        @arr.sort!{|a,b| (b.item_created_at).strftime("%Y-%m-%d") <=> (a.item_created_at).strftime("%Y-%m-%d")}
      rescue
      end
    elsif params[:type] == 'picture'
      begin
        @arr.sort!{|a,b| b.diff_score <=> a.diff_score}
      rescue
      end
    end

    if params[:type] == 'released' or params[:type] == 'upcoming'
      @array_name = @new_arr
    else
      @array_name = @arr
    end
    @result = @array_name.paginate(:page => params[:page], :per_page => PER_PAGE)

    if request.env["HTTP_REFERER"].blank?
      render :template => "/home_display/index"
    else
      unless params[:page].blank?
        respond_to do |format|
          format.js {}
        end
      else
        render :partial => "/home_display/load_language"
      end
    end

  end

end
