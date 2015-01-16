class TopTenController < ApplicationController
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token 
  before_filter :msn_redirect, :only => [:index, :slideshow, :slideshow_default]

  #layout 'website'
  layout:check

  def index
    if params[:release_year].blank?
      release_year = Time.new.year
    else 
      release_year = params[:release_year]
    end  
    start_date = "#{release_year}-01-01"
    end_date = "#{release_year}-12-31"
    @topten = []      
    @topten_celebs = [] 
    @all_topten = TopTen.where(:item_type => 0).where("rank != 0").order('created_at DESC')
    @all_topten.each do |top_ten|
      m_status = false
      items = TopTen.get_top_ten_items(top_ten.id)
      items.each do |item|
        @movie = Movie.find_by_id(item)
        if @movie
          if cookies[:hindi] == "yes" && @movie.language == "Hindi"
            m_status = true
          end
          if cookies[:english] == "yes" && @movie.language == "English"
            m_status = true
          end
          if cookies[:tamil] == "yes" && @movie.language == "Tamil"
            m_status = true
          end
          if cookies[:telugu] == "yes" && @movie.language == "Telugu"
            m_status = true
          end
        end
      end
      if m_status == true
        @topten << top_ten
      end
    end
    @all_top_celeb = TopTen.where(:item_type => 1).where("rank != 0").order('created_at DESC')
    @all_top_celeb.each do |top_ten|
      m_status = false
      items = TopTen.get_top_ten_items(top_ten.id)
      items.each do |item|
        @celeb = Celebrity.find_by_id(item)
        if @celeb
          if cookies[:hindi] == "yes" && @celeb.language && @celeb.language.include?("Hindi")
            m_status = true
          end
          if cookies[:english] == "yes" && @celeb.language && @celeb.language.include?("English")
            m_status = true
          end
          if cookies[:tamil] == "yes" && @celeb.language && @celeb.language.include?("Tamil")
            m_status = true
          end
          if cookies[:telugu] == "yes" && @celeb.language && @celeb.language.include?("Telugu")
            m_status = true
          end
        end
      end
      if m_status == true
        @topten_celebs << top_ten
      end
    end

    #.paginate(:page => params[:page], :per_page => 12)
    #@topten_celebs = TopTen.where(:item_type => 1).where("rank != 0").order('created_at DESC')
    #.paginate(:page => params[:page], :per_page => 12)
    @topten_by_years = TopTen.get_top_ten_by_muvimeter(true,cookies)
    @topten_by_tweets = TopTen.get_top_ten_upcoming_by_tweets(true,cookies)
    if params[:ajax] == "1"
      render :partial => "/top_ten/topten_page"
      return
    end
  end
  

  def create
    @topten = TopTen.new
    @list_type = params[:list_type]
    unless params[:name].blank?
        
      @top = TopTen.new
      @top.name = params[:name]
      @top.item_type = params[:topten_type] 
      @top.user_id = current_user.id
      items =  params[:id_item]
      notes = params[:note]
      ctr = 0
      item = []
      items.each do |id|
        if id != '0'
          item << {:id => id, :notes => notes[ctr]}
          ctr = ctr + 1
        end
      end
      @top.items = '{"items":'+ item.to_json + '}'
      @top.save
      redirect_to top_ten_path
    end   
  end
  
  def edit
    @topten = TopTen.find(params[:id])
    @list_type = @topten.item_type == 0 ? 'movies' : 'celebs'
    @movies_array = TopTen.get_top_ten_items(params[:id])
    @movies_note = TopTen.get_top_ten_item_notes(params[:id])
  end 
  def edit_default
   @list_type = 'movies'
   if params[:type] == 'default'
     @name = 'Top 10 Movies by Year'
     @movies_array = TopTen.get_top_ten_by_muvimeter(false,params[:release_year],params[:genre],params[:celebrity],10,cookies)
   elsif params[:type] == 'upcoming'
     @name = 'Top 10 Upcoming movies'
     @movies_array = TopTen.get_top_ten_upcoming_by_tweets(false,cookies)
   end
  end 
  def update
    send_mail = false
    unless params[:name].blank?
      if !params[:list_id].nil?
        @existing_list = TopTen.find(params[:list_id])
        if @existing_list.user_id == current_user.id
         @top = @existing_list
        else
         @top = TopTen.new
         send_mail = true
        end
      else
	@top = TopTen.new
      end
      @top.name = params[:name]
      @top.item_type = params[:topten_type]
      @top.user_id = current_user.id
      items =  params[:id_item]
      notes = params[:note]
      ctr = 0
      item = []
      items.each do |id|
        if id != '0'
          item << {:id => id, :notes => notes[ctr]}
          ctr = ctr + 1
        end
      end
      @top.items = '{"items":'+ item.to_json + '}'
      @top.save
      if send_mail == true
        subject = "#{@existing_list.name} got remixed"
        content = "<a href='#{SITE_URL}/profile/#{current_user.id}/#{current_user.display_name}'>#{current_user.display_name}</a> created a remix of <a href='#{SITE_URL}/top_ten/#{params[:list_id]}/#{@existing_list.name}'>#{@existing_list.name}</a>  at name of <a href='#{SITE_URL}/top_ten/#{@top.id}/#{@top.name}'>#{@top.name}</a>"
        u = User.find(@existing_list.user_id)
        Movie.send_notification("top_ten", :email => u.email, :subject => subject, :content => content)
       end

    end
    redirect_to top_ten_path
  end  
  def moviedropdown
   total_name_list = []
   puts params
   if params[:type] == 'movies'
    	total_name_list = Movie.select("id, name as label, poster_file_name as picture").where("release_date <= ? ", Date.today).order("name ASC").search(:name_starts_with => params[:term]).paginate(:page => 1, :per_page => 10)

        total_name_list.each do |m|
          poster = Tagging.where("t2.taggable_type = 'Poster' and t2.tagger_id='#{m.id}' and t2.tagger_type='Movie'").find(:all, :select => ["t2.taggable_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)= 'poster'"], :group => ["t2.taggable_id"]).first
          unless poster.blank?
            p = Poster.find_by_id(poster.taggable_id, :conditions => ["rank = 1"])
            unless p.blank?
              m["poster_file_name"] = p.poster_file_name
              m["poster_id"] = p.id
            end
          end
        end
   else
    	total_name_list = Celebrity.select("id, name as label, profile_picture_file_name as picture").order("cell_rank ASC nulls last, name ASC").search(:name_starts_with => params[:term]).paginate(:page => 1, :per_page => 10)

        total_name_list.each do |m|
          poster = Tagging.where("t2.taggable_type = 'Poster' and t2.tagger_id='#{m.id}' and t2.tagger_type='Celebrity'").find(:all, :select => ["t2.taggable_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)= 'profilepic'"], :group => ["t2.taggable_id"]).first
          unless poster.blank?
            p = Poster.find_by_id(poster.taggable_id, :conditions => ["rank = 1"])
            unless p.blank?
              m["poster_file_name"] = p.poster_file_name
              m["poster_id"] = p.id
            end
          end
        end
   end
    
    ActiveRecord::Base.include_root_in_json = false
    render :json => total_name_list.to_json
  end  
  
  def slideshow
    @topten = TopTen.find(params[:id]) rescue ''
    items = TopTen.get_top_ten_items(params[:id])
    notes = TopTen.get_top_ten_item_notes(params[:id])
    ctr = 0
    @movies_array = []
    @movies_notes = []
    item_array = []
    unless @topten.blank?
      items.each do |item|
         if @topten.item_type == 0
            @movie = Movie.find_by_id(item)
            if @movie
              m_status = false
              if cookies[:hindi] == "yes" && @movie.language == "Hindi"
                m_status = true
              end
              if cookies[:english] == "yes" && @movie.language == "English"
                m_status = true
              end
              if cookies[:tamil] == "yes" && @movie.language == "Tamil"
                m_status = true
              end
              if cookies[:telugu] == "yes" && @movie.language == "Telugu"
                m_status = true
              end
              #if m_status == true
                @movies_array << item
                @movies_notes << notes[ctr]
                item_array << {:id => item, :notes => notes[ctr]}
                ctr += 1
              #end
            end
         else
            @celebrity = Celebrity.find_by_id(item.to_i)
            unless @celebrity.blank?
              m_status = false
              if cookies[:hindi] == "yes" && @celebrity.language && @celebrity.language.include?("Hindi")
                m_status = true
              end
              if cookies[:english] == "yes" && @celebrity.language && @celebrity.language.include?("English")
                m_status = true
              end
              if cookies[:tamil] == "yes" && @celebrity.language && @celebrity.language.include?("Tamil")
                m_status = true
              end
              if cookies[:telugu] == "yes" && @celebrity.language && @celebrity.language.include?("Telugu")
                m_status = true
              end
              #if m_status == true
                @movies_array << item
                @movies_notes << notes[ctr]
                item_array << {:id => item, :notes => notes[ctr]}
                ctr += 1
              #end
            end
         end
      end
      #@topten.items = '{"items":'+ item_array.to_json + '}'
      #@topten.save
      @movies_array.reverse!
      @movies_notes.reverse!
    end
  end
  
  def slideshow_default
     @topten = 'Top 10'
   if params[:type] == 'default'
     @title = 'Top 10 Movies by Year'
     @selected_year = params[:release_year]
     @selected_genre = params[:genre]
     @selected_celebrity = params[:celebrity]
     @movies_array = TopTen.get_top_ten_by_muvimeter(false,@selected_year, @selected_genre,@selected_celebrity,10,cookies)
     @movies_array.reverse!
     @release_year = {'Any' => 'Any', '2012' => '2012', '2011' => '2011', '2010' => '2010', '2009' => '2009', '2000s' => '2000s', '1990s' => '1990s', '1980s' => '1980s', '1970s' => '1970s', 'Before 1970s' => 'Before 1970s'}
     @genres = {'all' => 'all' ,'Action' => 'Action', 'Drama' => 'Drama', 'Romance' => 'Romance'}
     @celebrities = {'all' => 'all','Aamir Khan' => '4406','Ajay Devgn' => '2622', 'Akshay Kumar' => '3847' , 'Amitabh Bachchan' => '1569' , 'Hrithik Roshan' => '4562','Imran Khan' => '1376','Ranbir Kapoor' => '1940','Salman Khan' => '923','Shahrukh Khan' => '3031'}
   elsif params[:type] == 'upcoming'
     @title = 'Top 10 Upcoming movies'
     @movies_array = TopTen.get_top_ten_upcoming_by_tweets(false,cookies)
     @movies_array.reverse!
   end
  end
  
 
end
