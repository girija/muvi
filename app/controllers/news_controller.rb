class NewsController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :msn_redirect, :only => [:index, :show]
  #layout 'website'
  layout:check

  def index
    @all_news = []
    @all_data = Feed.find(:all, :conditions => ["date(created_at) = ? and (rank != ? or rank IS NULL)",Date.today, 0], :order => ["created_at desc,  rank asc"])
    if @all_data.blank?
      @all_data = Feed.find(:all, :conditions => ["date(created_at) = ? and (rank != ? or rank IS NULL)", (Date.today - 1), 0], :order => ["created_at desc,  rank asc"])
    end
    @all_data.each do |data|
      tags = data.taggings
      tags.each do |tag|
        if cookies[:hindi] == "yes"
          if tag.tagger_type == "Celebrity"
            celeb = Celebrity.find_by_id(tag.tagger_id)
            if celeb && celeb.language && celeb.language.include?("Hindi")
              @all_news << data
            end
          else
            movie = Movie.find_by_id(tag.tagger_id)
            if movie && movie.language && movie.language == "Hindi"
              @all_news << data
            end
          end   
        end
        if cookies[:telugu] == "yes"
          if tag.tagger_type == "Celebrity"
            celeb = Celebrity.find_by_id(tag.tagger_id)
            if celeb && celeb.language && celeb.language.include?("Telugu")
              @all_news << data
            end
          else
            movie = Movie.find_by_id(tag.tagger_id)
            if movie && movie.language && movie.language == "Telugu"
              @all_news << data
            end
          end
        end
        if cookies[:english] == "yes"
          if tag.tagger_type == "Celebrity"
            celeb = Celebrity.find_by_id(tag.tagger_id)
            if celeb && celeb.language && celeb.language.include?("English")
              @all_news << data
            end
          else
            movie = Movie.find_by_id(tag.tagger_id)
            if movie && movie.language && movie.language == "English"
              @all_news << data
            end
          end
        end
        if cookies[:tamil] == "yes"
          if tag.tagger_type == "Celebrity"
            celeb = Celebrity.find_by_id(tag.tagger_id)
            if celeb && celeb.language && celeb.language.include?("Tamil")
              @all_news << data
            end
          else
            movie = Movie.find_by_id(tag.tagger_id)
            if movie && movie.language && movie.language == "Tamil"
              @all_news << data
            end
          end
        end
      end
    end
    @all_news = @all_news.uniq
    if params[:ajax] == "1"
      render :partial => "/news/news"
      return
    end
  end
  
  def show
    ####### Redirect based on msn embed page #####
    #if request.fullpath !~ /\/msn_embed/
    #  if request.env["HTTP_REFERER"] =~ /\/msn_embed/
    #    request.env["HTTP_HOST"] = request.env["HTTP_HOST"]+"/msn_embed"
    #    url = "http://"+request.env["HTTP_HOST"]+request.fullpath
    #    redirect_to url
    #  end
    #end
    ######## End msn redirect #####################

    @tagging = Tagging.find_by_id(params[:tagging_id])
    unless @tagging.blank?
      if params[:type] == "star"
        @celebrity = Celebrity.find_by_id(@tagging.tagger_id)
      elsif params[:type] == "movie"
        @movie = Movie.find_by_id(@tagging.tagger_id)
      end
      @feed = Feed.find_by_id(@tagging.taggable_id)
    end

  end

end
