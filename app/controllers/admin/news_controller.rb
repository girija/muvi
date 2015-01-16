class Admin::NewsController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  before_filter :admin?
  layout 'admin'

  def index
    #@all_news = Tagging.find(:all, :order => ["created_at desc"]).paginate(:page => params[:page])
    unless params[:date].blank?
      @all_feed = Feed.find(:all, :conditions => ["date(created_at) = ?", params[:date]], :order => ["created_at desc"]).paginate(:page => params[:page], :per_page => 100)
    else
      @all_feed = Feed.find(:all, :conditions => ["date(created_at) = ?", Date.today], :order => ["created_at desc"]).paginate(:page => params[:page], :per_page => 100)
    end
    @lang_feed = []
    unless params[:language] == ""
      @all_feed.each do |data|
        tags = data.taggings
        if params[:language] != "Untagged"
          tags.each do |tag|
            if tag.tagger_type == "Celebrity"
              celeb = Celebrity.find_by_id(tag.tagger_id)
              if celeb && celeb.language && celeb.language.include?("#{params[:language]}")
                @lang_feed << data
              end
            else
              movie = Movie.find_by_id(tag.tagger_id)
              if movie && movie.language == "#{params[:language]}"
                @lang_feed << data
              end
            end
          end
        else
          if tags.blank?
            @lang_feed << data
          end
        end
      end
      @all_feed = @lang_feed.uniq.paginate(:page => params[:page], :per_page => 100)
    end
  end
  
  def edit
    @news = News.find_by_id(params[:id])
  end

  def update
    @news = News.find_by_id(params[:id])
    feed = Feed.find_by_id(params[:id])
    #feed.tags.destroy_all
    feed.taggings.destroy_all
    @taggable_id = []
    @taggable_type = []
    #@tags = []
    #params[:news][:tag_list].split(",").each do |tag|
      #tag = tag.strip
      #@tags << tag
    #end
    if !params[:flag].blank? and feed.flag != params[:flag]
      feed.update_attributes(:flag=>params[:flag], :flag_set_at => Time.now)
    end
    if params[:flag].blank? && !feed.flag.blank?
      feed.update_attributes(:flag => params[:flag], :flag_set_at => "")
    end
  
    feed.rank = params[:news][:rank]
    feed.entry_title = params[:news][:entry_title]
    feed.tag_list = @tags
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
      feed.tag_list = @tags
      #home_page = HomePageSetting.where("subject_type = 'News' and subject_id = '#{feed.id}'")
      #if home_page.blank?
        #feed.history_score = feed.score
        #feed.diff_score = '0'
      #end
      if feed.save
        unless params[:add_score].blank?
          new_score = feed.score+params[:add_score].to_i
          feed.update_attribute('score', new_score)
          @activity = Activity.new
          @user = UserProfile.find_by_user_id(current_user.id)
          @activity.user_id = current_user.id
          @activity.secondary_subject_type = "News"
          @activity.subject_type = "Admin Score"
          @activity.secondary_subject_id = @news.id
          @activity.save(false)
        end
        @count = 0
        feed.taggings.order("id asc").each do |t|
          if @count == 0
            t.update_attribute("default_tag","true")
          end
          feed.taggings.order("id asc").each do |t|
            tagname = Tag.find_by_id(t.tag_id)
            @movie = Movie.where("lower(name) = ?", tagname.name.downcase).find(:first)
            unless @movie.blank?
              t.update_attributes(:tagger_id => @movie.id, :tagger_type => "Movie")
            end
            @celebrity = Celebrity.where("lower(name) = ?", tagname.name.downcase).find(:first)
            unless @celebrity.blank?
              t.update_attributes(:tagger_id => @celebrity.id, :tagger_type => "Celebrity")
            end
          end
          @count = @count + 1
        end
        format.html { redirect_to(params[:redirect_url], :notice => 'News successfully updated.') }
        format.xml  { head :ok }
      else
        @news.errors.add_to_base("News title can't be blank")
        format.html { render :action => "edit" }
        format.xml  { render :xml => @news.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete_news
    Feed.where('id = ?', params[:id]).destroy_all unless params[:id].blank?
    #redirect_to params[:redirect_url]
    begin
      redirect_to request.env["HTTP_REFERER"]
    rescue
      redirect_to admin_news_path
    end
  end

  def delete_news_multiple
    Feed.where('id in (?)', params[:feed_ids]).destroy_all unless params[:feed_ids].blank?
    #redirect_to params[:redirect_url]
    begin
      redirect_to request.env["HTTP_REFERER"]
    rescue
      redirect_to admin_news_path
    end
  end
end
