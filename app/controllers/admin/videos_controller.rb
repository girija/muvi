class Admin::VideosController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  require 'will_paginate/array'
  def index
    unless params[:search_tag].blank?
      @video_id = ""
      @tag = Tag.find(:all,:select => ["*"], :conditions => ["tags.name = '#{params[:search_tag]}' and taggings.taggable_type='Video'"], :joins => ["left join taggings on tags.id = taggings.tag_id"])
      unless @tag.blank?
        @tag.each do |t|
          unless t.taggable_id.blank?
            if @video_id.blank?
              @video_id = t.taggable_id
            else
              @video_id = @video_id +","+ t.taggable_id
            end
          end
        end
        @all_videos = Video.where("id IN (#{@video_id})").find(:all).paginate(:page => params[:page], :per_page => 100)
      end
    else
      @all_videos = Video.find(:all, :order => ["created_at desc"]).paginate(:page => params[:page], :per_page => 100)
    end
  end

  def add_video
    @video = Video.new(params[:videos])
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

      @video.tag_list = @tags
      if @video.save
        @video.taggings.order("id asc").each do |t|
           tagname = Tag.find_by_id(t.tag_id)
           @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
           unless @movie.blank?
             t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
           end

           @celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
           unless @celebrity.blank?
             t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
           end
           if tagname.name.downcase == "trailer"
             t.update_attribute("tagger_type", "trailer")
           end

           #Update media updated date for coming soon movies, 
           #Send emails to users for "New trailer or poster is released for the movie (for movie user wants to see)"
           Movie.update_comingsoon_movie("Video", "trailer", @video.id)
           #Ends here
        end
        unless params[:videos][:trailer].blank?
          @id = @video.id
          Video.create_thumbnail(@id,params[:videos][:trailer].original_filename)
        end
        format.html { redirect_to(admin_videos_path, :notice => 'Video successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @video = Video.find_by_id(params[:id])
  end

  def update
    @video = Video.find_by_id(params[:video_id])
    #@video.tags.destroy_all
    @video.taggings.destroy_all
    if !params[:flag].blank? and @video.flag != params[:flag]
      if params[:flag] == "Latest Trailer"
        flag_code = 5
      end
      @video.update_attributes(:flag=>params[:flag], :flag_set_at => Time.now)
    end
    if params[:flag].blank? && !@video.flag.blank?
      @video.update_attributes(:flag => params[:flag], :flag_set_at => "")
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

      @video.tag_list = @tags
      #home_page = HomePageSetting.where("subject_type = 'Video' and subject_id = '#{@video.id}'")
      #if home_page.blank? && @video.updated_at < Date.today
        #params[:video][:history_score] = @video.score
        #params[:video][:diff_score] = '0'
      #end
      if @video.update_attributes(params[:video])
        unless params[:add_score].blank?
          new_score = @video.score+params[:add_score].to_i
          @video.update_attribute('score', new_score)
          @activity = Activity.new
          @user = UserProfile.find_by_user_id(current_user.id)
          @activity.user_id = current_user.id
          @activity.secondary_subject_type = "Video"
          @activity.subject_type = "Admin Score"
          @activity.secondary_subject_id = @video.id
          @activity.save(false)
        end
        @video.taggings.order("id asc").each do |t|
          tagname = Tag.find_by_id(t.tag_id)
          @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)

          unless @movie.blank?
            t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
          end
          @celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
          unless @celebrity.blank?
            t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
          end
          if tagname.name.downcase == "trailer"
            t.update_attribute("tagger_type", "trailer")
          end

        end

        #Update media updated date for coming soon movies,
        #Send emails to users for "New trailer or poster is released for the movie (for movie user wants to see)"
        Movie.update_comingsoon_movie("Video", "trailer", @video.id)
        #Ends here

        #save thumbnail
        unless params[:video][:trailer].blank?
          begin
            (Rails.root + "public/system/trailer_thumbnails/#{params[:video_id]}/").rmtree
          rescue
          end
          Video.create_thumbnail(params[:video_id],params[:video][:trailer].original_filename)
        end

        format.html { redirect_to(admin_videos_path, :notice => 'News successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }
      end
    end
  end


  def delete
    unless params[:id].blank?
      if Video.where('id = ?', params[:id]).destroy_all
        begin
          #(Rails.root + "public/system/trailer_thumbnails/#{params[:id]}/").rmtree
          system ("s3cmd del s3://#{BUCKET}/public/system/trailer_thumbnails/#{params[:id]}/1.jpg")
        rescue
        end
      end
    end
    redirect_to admin_videos_path
  end

  def add_trailer_from_page
    render :partial => "add_trailer_from_page"
  end


  def add_video_from_page
    if params[:new_trailer].to_i == 1
      @video = Video.new(params[:videos])
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
        @video.tag_list = @tags
        if @video.save
          @video.taggings.order("id asc").each do |t|
             tagname = Tag.find_by_id(t.tag_id)
             @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
             unless @movie.blank?
               t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
             end

             #@celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
             #unless @celebrity.blank?
             #  t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
             #end
             if tagname.name.downcase == "trailer"
               t.update_attribute("tagger_type", "trailer")
             end
          end
          unless params[:videos][:trailer].blank?
            @id = @video.id
            Video.create_thumbnail(@id,params[:videos][:trailer].original_filename)
          end

          format.html { redirect_to(request.env["HTTP_REFERER"], :notice => 'Video successfully updated.') }
          format.xml  { head :ok }
        else
          format.html { render :action => "index" }
          format.xml  { render :xml => @video.errors, :status => :unprocessable_entity }

        end
      end
    else
       # update video
       @video = Video.find(params[:video_id])
       @video.update_attributes(params[:videos])
       unless params[:videos][:trailer].blank?
          @id = params[:video_id]
          Video.create_thumbnail(@id,params[:videos][:trailer].original_filename)
       end
       redirect_to(request.env["HTTP_REFERER"], :notice => 'Video successfully updated.')
    end
  end

end

