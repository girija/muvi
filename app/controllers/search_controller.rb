class SearchController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :msn_redirect, :only => [:index]
  #layout 'website'
  layout:check

  def index
    search_box_val = ""
    if params[:msn_embed] == "msn_embed"
      search_box_val = params[:q1]
    else
      search_box_val = params[:q]
    end
    term = search_box_val.strip.gsub(/[']/, '\\\\\'')

    @mov_search = Movie.solr_search do
                      fulltext term
                      paginate page: 1, per_page: 4
                  end
    @movies = @mov_search.results
    @celeb_search = Celebrity.solr_search  do
                      fulltext term
                      paginate page: 1, per_page: 4
                    end
    @celebrities = @celeb_search.results

    @user_search = User.solr_search  do
                  fulltext term
                  paginate page: 1, per_page: 4
                end
    @users = @user_search.results

    #term = params[:q].strip.gsub(/[']/, '\\\\\'')
    #tag = {:tag_contains => term}
    #condition = "tag ILIKE ?", "#{term}%"
    #@list_search = UserMovieList.where(condition).search(tag)
    #@lists = @list_search.paginate(:page => params[:page], :per_page => 4)

    @list_search = UserMovieList.solr_search  do
                      fulltext term
                      paginate page: 1, per_page: 4
                    end
    @lists = @list_search.results

    if @movies.size == 1 && @celebrities.blank?
        redirect_to movie_path(@movies.first) and return
    end
    if @movies.blank? && @celebrities.size == 1
      #redirect_to celebrity_path(@celebrities.first.id) and return
      redirect_to star_path(@celebrities.first) and return
    end

  end

  def get_static_file
    data = File.read("#{RAILS_ROOT}/assets/fonts/#{params[:f_name]}.#{params[:format]}")
    if params[:format] == "svg"
      content_type = "image/svg+xml"
    elsif params[:format] == "ttf"
      content_type = "application/x-font-ttf"
    elsif params[:format] == "otf"
      content_type = "application/x-font-ttf"
    elsif params[:format] == "woff"
      content_type = "application/x-font-woff"
    elsif params[:format] == "eot"
      content_type = "application/vnd.ms-fontobject"
    end
    render :text => data, :content_type =>content_type
  end

end

