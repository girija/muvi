class Admin::PostersController < ApplicationController
  require 'paperclip_processors/cropper' 

  before_filter :authenticate_user!
  before_filter :admin?
  skip_before_filter :verify_authenticity_token
  layout 'admin'

  require 'will_paginate/array'

  def index
    per_page = 100
    page = params[:page].blank? ? 1 : params[:page]
    page = page.to_i

    unless params[:search_tag].blank?
      @poster_id = ""
      #term = params[:search_tag].strip.gsub(/[']/, '\\\\\'')
      term =  params[:search_tag].strip
      @tag = Tag.find(:all,:select => ["*"], :conditions => ["tags.name = ? and taggings.taggable_type='Poster'", term], :joins => ["left join taggings on tags.id = taggings.tag_id"])

      unless @tag.blank?
        @tag.each do |t|
          unless t.taggable_id.blank?
            if @poster_id.blank?
              @poster_id = t.taggable_id
            else
              @poster_id = @poster_id +","+ t.taggable_id
            end
          end
        end
        @all_posters = Poster.where("id IN (#{@poster_id})").find(:all, :limit => per_page + 1, :offset => (page - 1) * per_page).paginate(:page => params[:page], :per_page => 100)
        @poster_count = Poster.where("id IN (#{@poster_id})").count
      end
    else
      @all_posters = Poster.find(:all, :limit => per_page + 1, :offset => (page - 1) * per_page, :order => ["created_at desc"])
      #.paginate(:page => params[:page], :per_page => 10)
      @poster_count = Poster.count
    end
    
  end

  def add_poster
    @poster = Poster.new(params[:posters])
    respond_to do |format|
      @tags = []
      unless params[:movie_tag].blank?
        params[:movie_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      unless params[:celebrity_tag].blank?
        params[:celebrity_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      unless params[:other_tag].blank?
        params[:other_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      @poster.tag_list = @tags
      if @poster.save

        @poster.taggings.order("id asc").each do |t|
           tagname = Tag.find_by_id(t.tag_id)
           @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
           unless @movie.blank?
             t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
           end
           @celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
           unless @celebrity.blank?
             t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
           end
           if tagname.name.downcase == "poster"
             t.update_attribute("tagger_type", "poster")
           end
           if tagname.name.downcase == "profilepic"
             t.update_attribute("tagger_type", "profilepic")
           end
        end


        #Update media updated date for coming soon movies,
        #Send emails to users for "New trailer or poster is released for the movie (for movie user wants to see)"
        Movie.update_comingsoon_movie("Poster", "poster", @poster.id)
        #Ends here

        #format.html { redirect_to(admin_posters_path, :notice => 'Poster successfully updated.') }
        format.html { redirect_to :conroller => "admin/posters", :action => "crop", :poster => @poster}
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @poster.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @poster = Poster.find_by_id(params[:id])
  end

  def update
    existing_score = 0
    @poster = Poster.find_by_id(params[:poster_id])
    #@poster.tags.destroy_all
    @poster.taggings.destroy_all
    if  !params[:flag].blank? and @poster.flag != params[:flag]
      @poster.update_attributes(:flag=>params[:flag], :flag_set_at => Time.now)
    end
    if params[:flag].blank? && !@poster.flag.blank?
      @poster.update_attributes(:flag => params[:flag], :flag_set_at => "")
    end

    respond_to do |format|
      @tags = []
      unless params[:movie_tag].blank?
        params[:movie_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      unless params[:celebrity_tag].blank?
        params[:celebrity_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      unless params[:other_tag].blank?
        params[:other_tag].split(",").each do |tag|
          tag = tag.strip
          @tags << tag
        end
      end

      @poster.tag_list = @tags
      #home_page = HomePageSetting.where("subject_type = 'Poster' and subject_id = '#{@poster.id}'")
      #if home_page.blank? && @poster.updated_at < Date.today
        #params[:poster][:history_score] = @poster.score
        #params[:poster][:diff_score] = '0'
      #end
      if @poster.update_attributes(params[:poster])
        @poster.taggings.order("id asc").each do |t|
          tagname = Tag.find_by_id(t.tag_id)
          @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
          unless @movie.blank?
            t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
          end
          @celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
          unless @celebrity.blank?
            t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
          end
          if tagname.name.downcase == "poster"
             t.update_attribute("tagger_type", "poster")
          end
          if tagname.name.downcase == "profilepic"
            t.update_attribute("tagger_type", "profilepic")
          end
        end
        unless params[:add_score].blank?
          unless @poster.score.blank?
            existing_score = @poster.score.to_i
          else
            existing_score = 0
          end
          @activity = Activity.new
          @user = UserProfile.find_by_user_id(current_user.id)
          @activity.user_id = current_user.id
          @activity.secondary_subject_type = "Poster"
          @activity.subject_type = "Admin Score"
          @activity.secondary_subject_id = @poster.id
          @activity.save(false)
          new_score = existing_score + params[:add_score].to_i

          @poster.update_attribute('score', new_score)
        end

        #Update media updated date for coming soon movies,
        #Send emails to users for "New trailer or poster is released for the movie (for movie user wants to see)"
        Movie.update_comingsoon_movie("Poster", "poster", params[:poster_id])
        #Ends here
        
        unless params[:poster][:crop_x].blank?
          format.html { redirect_to(admin_posters_path, :notice => 'Poster successfully updated.') }
        else
          #####
          if !params[:poster][:poster_remote_url].blank? or !params[:poster][:poster].blank?
            format.html { render :action => "crop"}
          else
            format.html { redirect_to(admin_posters_path, :notice => 'Poster successfully updated.') }
          end
          #####
        end
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @poster.errors, :status => :unprocessable_entity }
      end
    end
  end


  def delete
    unless params[:id].blank?
      Poster.where('id = ?', params[:id]).destroy_all
    end
    redirect_to admin_posters_path
  end

  def update_crop
    poster = Poster.find_by_id(params[:poster_id])

    poster.crop_x = params[:poster][:crop_x]
    poster.crop_y = params[:poster][:crop_y]
    poster.crop_w = params[:poster][:crop_w]
    poster.crop_h = params[:poster][:crop_h]
    #poster.update_attributes(poster)
    poster.save!
    poster.poster.reprocess!

    redirect_to(admin_posters_path, :notice => 'Poster successfully updated.')
  end

  def delete
    unless params[:id].blank?
      Poster.where('id = ?', params[:id]).destroy_all
    end
    redirect_to admin_posters_path
  end


  def crop
    @poster = Poster.find(params[:poster])
    
  end

  def crop_poster
    @poster = Poster.find(params[:poster])
    if params[:referer_url] =~ /\/admin/

    else
      render :layout => "new_home"
    end
  end

  def poster_from_page
    @poster = Poster.find_by_id(params[:poster_id])
    render :partial => "poster_from_page"
  end

  def save_poster_from_page
    if params[:new_poster].to_i == 1
      @poster = Poster.new(params[:poster])
      #respond_to do |format|
        @tags = []
        unless params[:movie_tag].blank?
          params[:movie_tag].split(",").each do |tag|
            tag = tag.strip
            @tags << tag
          end
        end

        unless params[:other_tag].blank?
          params[:other_tag].split(",").each do |tag|
            tag = tag.strip
            @tags << tag
          end
        end
        @poster.tag_list = @tags
        if @poster.save
          @poster.taggings.order("id asc").each do |t|
             tagname = Tag.find_by_id(t.tag_id)
             @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
             unless @movie.blank?
               t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
             end
             if tagname.name.downcase == "poster"
               t.update_attribute("tagger_type", "poster")
             end
          end
        end
      #end

    else
      @poster = Poster.find_by_id(params[:poster_id])
      @poster.update_attributes(params[:poster])
    end

    unless params[:poster][:crop_x].blank?
      format.html { redirect_to(admin_posters_path, :notice => 'Poster successfully updated.') }
    else
      if !params[:poster][:poster_remote_url].blank? or !params[:poster][:poster].blank?
        redirect_to :conroller => "admin/posters", :action => "crop_poster", :poster => @poster, :movie_id => params[:movie_id], :referer_url => params[:referer_url]
      else
        redirect_to "#{request.env["HTTP_REFERER"]}"
      end
    end
    #render :layout => "new_home"
  end

  def update_crop_page
    poster = Poster.find_by_id(params[:poster_id])

    poster.crop_x = params[:poster][:crop_x]
    poster.crop_y = params[:poster][:crop_y]
    poster.crop_w = params[:poster][:crop_w]
    poster.crop_h = params[:poster][:crop_h]
    poster.save!
    poster.poster.reprocess! 

    if params[:referer_url] =~ /\/admin/
      redirect_to(admin_movies_path, :notice => 'Poster successfully updated.')
    else
      movie = Movie.find(params[:movie_id])
      redirect_to movie_path(movie)
    end
  end

end

