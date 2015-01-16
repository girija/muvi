class Admin::MoviesController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token 
  before_filter :admin?
  layout 'admin'

  require "will_paginate/array"

  def index
    unless params[:commit].blank?
      name_contains = params[:name_contains].strip.gsub(/[']/, '\\\\\'')
      #content_partner = params[:content_partner].strip.gsub(/[']/, '\\\\\'')
      content_partner = params[:content_partner]

      @where = ""  
      @join = ""

      if params[:release_date_gteq].to_s != ""
        @where += " and DATE(release_date) >= '#{params[:release_date_gteq]}'"
      end

      if params[:release_date_lteq].to_s != ""
        @where += " and DATE(release_date) <= '#{params[:release_date_lteq]}'"
      end

      if params[:available_to_watch].to_i == 1
        @where += " and movie_streams.id IS NOT NULL and movie_streams.youtube != ''"
        @join = "left join movie_streams on films.id = movie_streams.movie_id"

      elsif content_partner.to_s != ""
        @su = StudioUser.where("LOWER(studio_users.company) = '#{content_partner.downcase}' ").select("id").find(:all)
        unless @su.blank?
          studio_user_id = ""
          @su.each do |su|
            if studio_user_id.blank?
              studio_user_id = su.id
            else
              studio_user_id = studio_user_id.to_s + "," + su.id.to_s
            end
          end

          @where += " and movie_streams.id IS NOT NULL"
          @join += "left join movie_streams on films.id = movie_streams.movie_id and movie_streams.studio_user_id IN (#{studio_user_id})"
        end    #unless @su blank if
      end
     
      if name_contains != "" or params[:release_date_gteq] != "" or params[:release_date_lteq] != "" or content_partner != "" or params[:available_to_watch].to_i == 1

        name_contains = name_contains.downcase
        @search = Movie.select("films.*").where("films.id IS NOT NULL #{@where}").order('release_date desc nulls last').find(:all,:conditions => ["LOWER(films.name) ILIKE ?", "%#{name_contains}%"], :joins => @join)
      else
        @search = Movie.order('release_date desc nulls last').find(:all)
      end
      @movies = @search.paginate(:page => params[:page], :per_page => 50)
    end
  end

  def index_old
    unless params[:search].blank?
      @search = Movie.latest.search(params[:search])
      @movies = @search.paginate(:page => params[:page], :per_page => 50)
    end
  end

  def show
    @movie = Movie.find_using_id(params[:id]).includes([:movie_casts]).first
    @actors = []
    @movie.movie_casts.each do |cast|
      case cast.cast_type
      when 'actor' then @actors << cast
      when 'director' then @director = cast
      when 'producer' then @producer = cast
      when 'writer' then @writer = cast
      when 'musics' then @music = cast
      end
    end
  end

  def new
   @movie = Movie.new
   @movie.build_meta_detail
   #@movie.actors.build
   #@movie.crew_members.build
   #@movie.video.build
   #@movie.poster.build
  end

  def edit
    @movie = Movie.find_using_id(params[:id]).includes([ :tweets,:movie_casts, :comments, :actors]).first
    @movie_stream = MovieStream.find_by_movie_id(@movie.id)
    @movie.build_meta_detail if @movie.meta_detail.blank?
    @mov_cast = MovieCast.find(:all,:select => ["celebrity_id,sum(id || ',') as all_id,sum(cast_type || ',') as all_cast_type,sum(celebrity_id || ',') as all_celebrity_id,sum(role_name || ',') as all_role_name"], :conditions => ["movie_id = ?",@movie.id], :group => ["celebrity_id,person_priority"], :order => ["person_priority"])
    #unless @movie.poster_file_name.blank?
    #  poster = Poster.find_by_movie_id(@movie.id)
    #  if poster.blank? or poster.nil?
    #     @poster = Poster.new
    #     @poster.movie_id = @movie.id
    #     @poster.poster_file_name = @movie.poster_file_name
    #     @poster.poster_content_type = @movie.poster_content_type
    #     @poster.poster_file_size = @movie.poster_file_size
    #     @poster.default_poster = "t"
    #     if @poster.save
    #       if !@poster.id.blank? and !@poster.id.nil? and !@movie.id.blank? and  !@movie.id.nil?
    #         system('sudo cp -r public/system/posters/'"#{@movie.id}"' public/system/posters/'"#{@poster.id}"'')
    #       end
    #     end
    #  end
    #end
    #Movie.update_one_movie_percentage(@movie)

  end

  def create
    items = []
    ctr = 0
    params[:related_movies_id].each do |muvi|
      item = {}
      if muvi != ''
        item['id'] =  muvi
        item['type'] =  params[:relation_type][ctr]
        items << item
      end
      ctr += 1
    end
    params[:movie][:related_movies] = items.to_json
    @movie = Movie.new(params[:movie])
    @movie.name = params[:movie][:name].strip
    respond_to do |format|
      if @movie.save
        Movie.set_related_movie(@movie)

        ##################
        unless params[:cast_type].blank?
          cnt = 0
          params[:cast_type].each {|k,v|
           v.each do |ct|
             mov_cast = MovieCast.new
              mov_cast.movie_id = @movie.id
              mov_cast.cast_type = ct
              mov_cast.celebrity_id = params[:name][cnt]
              if ct == "actor"
                mov_cast.role_name = params[:characters][cnt]
              end
              mov_cast.person_priority = (cnt + 1)
              mov_cast.save

              #AllActivity.add_filmography_notification(@movie.id, mov_cast.celebrity_id)
              ######## Add activity saying a movie is added for this celeb

	      celeb_follow = Follow.find(:all, :conditions => ["followable_id = #{mov_cast.celebrity_id} and followable_type = 'Celebrity'"])
	      unless celeb_follow.blank?
	        act = AllActivity.new
                act.movie_id = @movie.id
                act.activity_type = "new movie added"
                act.activity = AllActivity.create_movie_added_json(@movie.id, mov_cast.celebrity_id)
                act.save
              end	      
	      #####
             end
            cnt = cnt + 1
          }
        end

       ############## ADD YOUTUBE LINK #################
       unless params[:youtube_link].blank?
         chk_movie_stream = MovieStream.find_by_movie_id(@movie.id)
         unless chk_movie_stream.blank?
           chk_movie_stream.update_attribute("youtube", params[:youtube_link])
         else
           movie_stream = MovieStream.new
           movie_stream.movie_id = @movie.id
           movie_stream.youtube = params[:youtube_link]
           if @movie.content_type == "Movie"
             movie_stream.is_episode = 0
           else
             movie_stream.is_episode = 1
           end
           movie_stream.save
         end
       end
       ################################################

       #################
       #critics_percent = @movie.critics_reviews.blank? ? 0 : (100 * @movie.critics_reviews.select("SUM(rating) as total").first.total.to_i) / (@movie.critics_reviews.count * 5)
       #@movie.update_attribute('critics_percent', critics_percent) unless @movie.critics_percent == critics_percent
       Movie.delay.update_one_movie_percentage(@movie)
       ##############

       # ActivityUpdate.new_movie
       format.html { redirect_to(edit_admin_movie_path(@movie), :notice => 'Movies was successfully created.') }
       format.xml  { render :xml => @movie, :status => :created, :location => @movie }
      else
       format.html { render :action => "new" }
       format.xml  { render :xml => @movie.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @movie = Movie.find_using_id(params[:id]).first
    if !params[:flag].blank? and  params[:flag] != @movie.flag
      @movie.update_attributes(:flag => params[:flag], :flag_set_at => Time.now)
    end
    if params[:flag].blank? && !@movie.flag.blank?
      @movie.update_attributes(:flag => params[:flag], :flag_set_at => "")
    end
    items = []
    ctr = 0
    unless  params[:related_movies_id].blank?
      params[:related_movies_id].each do |muvi|
        item = {}
        if muvi != ''
          item['id'] =  muvi
          item['type'] =  params[:relation_type][ctr]
          items << item
        end
        ctr += 1
      end
    end

    params[:movie][:related_movies] = items.to_json

    respond_to do |format|
      params[:movie][:name] = params[:movie][:name].strip
      #home_page = HomePageSetting.where("subject_type = 'Movie' and subject_id = '#{@movie.id}'")
      #if home_page.blank? && @video.updated_at < Date.today
        #params[:movie][:history_score] = @movie.score
        #params[:movie][:diff_score] = '0'
      #end
      if @movie.update_attributes(params[:movie])
        Movie.set_related_movie(@movie)    
        ##################
        @existing_moviecast_id = ""
        @existing_movie_cast = MovieCast.find(:all, :select => ["sum(id || ',') as existing_moviecast_id"], :conditions => ["movie_id = ?",@movie.id])
        if @existing_movie_cast.size > 0
          @existing_moviecast_id = @existing_movie_cast[0].existing_moviecast_id
        end
        unless params[:add_score].blank?
          new_score = @movie.score+params[:add_score].to_i
          @movie.update_attribute('score', new_score)
          @activity = Activity.new
          @user = UserProfile.find_by_user_id(current_user.id)
          @activity.user_id = current_user.id
          @activity.secondary_subject_type = "Movie"
          @activity.subject_type = "Admin Score"
          @activity.secondary_subject_id = @movie.id
          @activity.save(false)
        end
        if !params[:cast_type].blank?
          cnt = 0
          params[:cast_type].each {|k,v|
           v.each do |ct|
             mov_cast = MovieCast.new
              mov_cast.movie_id = @movie.id
              mov_cast.cast_type = ct
              mov_cast.celebrity_id = params[:name][cnt]
              if ct == "actor"
                mov_cast.role_name = params[:characters][cnt]
              end
              mov_cast.person_priority = (cnt + 1)
              unless params[:name][cnt].blank?
                mov_cast.save
              end
             end
            cnt = cnt + 1
          }
        end
        @existing_moviecast_id.chop.split(",").each do |m|
           unless m.blank?
             MovieCast.destroy(m)
           end
         end

       ############## ADD YOUTUBE LINK #################
       unless params[:youtube_link].blank?
         chk_movie_stream = MovieStream.find_by_movie_id(@movie.id)
         unless chk_movie_stream.blank?
           chk_movie_stream.update_attribute("youtube", params[:youtube_link])
         else
           movie_stream = MovieStream.new
           movie_stream.movie_id = @movie.id
           movie_stream.youtube = params[:youtube_link]
           if @movie.content_type == "Movie"
             movie_stream.is_episode = 0
           else
             movie_stream.is_episode = 1
           end

           movie_stream.save
         end
       else
         chk_movie_stream = MovieStream.find_by_movie_id(@movie.id)
         unless chk_movie_stream.blank?
           chk_movie_stream.update_attribute("youtube", params[:youtube_link])
         end
       end
       ################################################
       
       #################
        #critics_percent = @movie.critics_reviews.blank? ? 0 : (100 * @movie.critics_reviews.select("SUM(rating) as total").first.total.to_i) / (@movie.critics_reviews.count * 5)
       #@movie.update_attribute('critics_percent', critics_percent) unless @movie.critics_percent == critics_percent
       ###############
       #poster = Poster.find_by_movie_id(@movie.id, :conditions => ["default_poster = 't'"])
       #if !poster.blank? and !poster.nil?
       #  @movie.update_attributes(:poster_file_name => poster.poster_file_name,
       #                         :poster_content_type => poster.poster_content_type,
       #                         :poster_file_size => poster.poster_file_size)
       #  if !poster.id.blank? and !poster.id.nil? and !@movie.id.blank? and  !@movie.id.nil?                      
       #    system('sudo rm -rf public/system/posters/'"#{@movie.id}"'/')
       #    system('sudo cp -r public/system/posters/'"#{poster.id}"' public/system/posters/'"#{@movie.id}"'')
       #  end
       #end
       
       ##############
        format.html { redirect_to(edit_admin_movie_path(@movie), :notice => 'movie was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @movie.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @movie = Movie.find_using_id(params[:id]).first
    if @movie.comments.destroy_all
      Activity.where("secondary_subject_id = #{@movie.id} and secondary_subject_type = 'Movie'").destroy_all
      @movie.destroy
    end
    redirect_to(admin_movies_url)
  end

  def addmore
    render :partial => "movie_actor_crew"
  end

  #def destroy_poster
  #  @movie = Movie.find_using_id(params[:id]).first
  #  poster = Poster.find_by_id(params[:poster_id])
  #  unless poster.blank?
  #    if poster.default_poster == true
  #      @movie.update_attributes(:poster_file_name => "",:poster_content_type => "", :poster_file_size => "")
  #      if !@movie.id.blank? and  !@movie.id.nil?
  #        system('sudo rm -rf public/system/posters/'"#{@movie.id}"'')
  #      end
  #    end
  #    poster.destroy
  #  end
  #  redirect_to(edit_admin_movie_path(@movie))
  #end


  #def destroy_trailer
  #  @movie = Movie.find_using_id(params[:id]).first
  #  video = Video.find_by_id(params[:video_id])
  #  video.destroy
  #  redirect_to(edit_admin_movie_path(@movie))
  #end

  def autocomplete
    movie_names = Movie.where("name ILIKE '#{params[:term].strip}%'").search.all.collect do |user|
      {"id" => user.id, "label" => user.name}
    end
    render :json => movie_names.to_json
  end

  def rotten_reviews
    critics_html = Nokogiri::HTML(open("#{params[:link]}"))
    critic_list = []
    critics_html.xpath(".//*[@id='reviews']/div/table/tr").each do |divs|
      critics_name =  divs.xpath("td[2]/a").text.strip
      review_description = divs.xpath("td[5]/p").text.strip
      review_link =  divs.xpath("td[5]/div[2]/a[1]/@href").text.strip
      if divs.xpath("td[4]/div[contains(@class,'fresh')]").size == 1
        review_score = 4
      else
        review_score = 2
      end
      if !critics_name.blank?
      if critics_name.force_encoding("UTF-8").ascii_only?
        puts "#{critics_name}<br>".html_safe
        critic = FilmCritic.find_by_name(critics_name)
        p(critic)
        if critic
          if review_description.force_encoding("UTF-8").ascii_only?
            critic_list += ["id" => critic.id ,"name" => critics_name.to_s, :description => review_description, :link => review_link, :score => "#{review_score}.0"]
          end
        end
      end
      end
    end
    render :json => critic_list.to_json
  end

  def edit_movie_from_page
    @movie = Movie.find_by_id(params[:movie_id])
    unless @movie.blank?
      @movie.name = params[:movie_name]
      @movie.release_date = params[:movie_released_date]
      @movie.story = params[:movie_story]
      @movie.additional_info = params[:movie_additional_info]

      unless params[:movie_genre].blank?
        genre = []
        params[:movie_genre].each do |g|
          genre << g
        end
      end

      @movie.genre = genre
      @movie.language = params[:movie_language]
      @movie.save
    end
    #puts params
    respond_to do |format|
      #format.html  {redirect_to root_path}
      format.js
    end
  end

  def remove_movie_casts
    movie_casts = MovieCast.find_by_id(params[:cast_table_id])
    unless movie_casts.blank?
      movie_casts.delete
    end
    render :text => 1
  end

  def addmore_casting
    render :partial => "addmore_casting"
  end

  def save_casting_from_page
    params[:cast_type].each do |cast|
      movie_casts = MovieCast.new
      movie_casts.movie_id = params[:movie_id]
      movie_casts.celebrity_id = params[:cast_id]
      movie_casts.role_name = params[:characters]
      movie_casts.cast_type = cast
      movie_casts.save
      @movie_casts_id =  movie_casts.id
      @cast_id = params[:cast_id]

      @cast_name = params[:castname]
      @celeb = Celebrity.find(params[:cast_id])
      @cast_type = cast
    end
  end

  def add_movie_from_page
    @movie = Movie.new(params[:movie])
    @movie.name = params[:movie][:name].strip
    if @movie.save
      count = 0
      cnt = 0
      ##################
      unless params[:actors].blank?
          params[:actors].each do |a|
            unless a.blank?
                mov_cast = MovieCast.new
                mov_cast.movie_id = @movie.id
                mov_cast.cast_type = "actor"
                mov_cast.celebrity_id = params[:actor_name][cnt]
                mov_cast.person_priority = count + 1
                mov_cast.save
                cnt = cnt + 1
                count = count + 1
            end
          end
        end

        cnt_1 = 0
        unless params[:directors].blank?
          params[:directors].each do |d|
            unless d.blank?
                mov_cast = MovieCast.new
                mov_cast.movie_id = @movie.id
                mov_cast.cast_type = "director"
                mov_cast.celebrity_id = params[:director_name][cnt_1]
                mov_cast.person_priority = count + 1
                mov_cast.save
                cnt_1 = cnt_1 + 1
                count = count + 1
            end
          end
        end

        cnt_2 = 0
        unless params[:producers].blank?
          params[:producers].each do |p|
            unless p.blank?
                mov_cast = MovieCast.new
                mov_cast.movie_id = @movie.id
                mov_cast.cast_type = "producer"
                mov_cast.celebrity_id = params[:producer_name][cnt_2]
                mov_cast.person_priority = count + 1
                mov_cast.save
                cnt_2 = cnt_2 + 1
                count = count + 1
            end
          end
        end

        #################
      respond_to do |format|
        format.js
      end
    end
  end

  def submit_grade
    params[:movie_grade].each do |mg|
      movie_id = mg[0]
      movie_grade = mg[1]

        puts "update"
        mov = Movie.find(movie_id)
        mov.update_attribute("grade", movie_grade)
    end
    redirect_to request.env["HTTP_REFERER"]
  end
  
  def curate_movies
    @bol_movies = []
    @hol_movies = []
    @curated_movies = CuratedMovie.first
    if @curated_movies
      @bol_movies = ActiveSupport::JSON.decode(@curated_movies.bol_movies)if !@curated_movies.bol_movies.blank? 
      @hol_movies = ActiveSupport::JSON.decode(@curated_movies.hol_movies)if !@curated_movies.hol_movies.blank?
    end 
  end

  def curate_autocomplete
    movie_names = Movie.where("name ILIKE '#{params[:term].strip}%' and language = '#{params[:lang]}'").search.all.collect do |movie|
      {"id" => movie.id, "label" => movie.name}
    end
    render :json => movie_names.to_json

  end

  def add_curate_movie
    @bol_movies = []
    @hol_movies  = []
    c_movie = CuratedMovie.first
    if c_movie.nil? || c_movie.blank?
      c_movie = CuratedMovie.new
      if params[:lang] == "Hindi"
        c_movie.bol_movies = "[#{params[:movie_id]}]"
      else
        c_movie.hil_movies = "[#{params[:movie_id]}]"
      end 
      c_movie.save  
    else
      @bol_movies  = ActiveSupport::JSON.decode(c_movie.bol_movies) if !c_movie.bol_movies.blank?
      @hol_movies  = ActiveSupport::JSON.decode(c_movie.hol_movies) if !c_movie.hol_movies.blank?
      if params[:lang] == "Hindi"
        @bol_movies << params[:movie_id].to_i
        c_movie.bol_movies = @bol_movies.to_json
      else
        @hol_movies << params[:movie_id].to_i
        c_movie.hol_movies = @hol_movies.to_json
      end
      c_movie.save
    end
    render :partial => "curated_list",:locals => {:bol_movies => @bol_movies,:hol_movies => @hol_movies}
  end

  def remove_curate
    c_movie = CuratedMovie.first
    movies = []
    if params[:lang] == "bol"
      @bol_movies = ActiveSupport::JSON.decode(c_movie.bol_movies)
      @bol_movies.each do |mov|
        if mov.to_i != params[:movie_id].to_i
          movies << mov
        end
      end
      c_movie.update_attribute('bol_movies',movies.to_json)
    else
      @hol_movies = ActiveSupport::JSON.decode(c_movie.hol_movies)
      @hol_movies.each do |mov|
        if mov.to_i != params[:movie_id].to_i
          movies << mov
        end
      end
      c_movie.update_attribute('hol_movies',movies.to_json)
    end
    redirect_to request.env["HTTP_REFERER"] 
  end
end
