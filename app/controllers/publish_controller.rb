class PublishController < ApplicationController
  skip_before_filter :authenticate_user!
  layout nil
  #session :off

  def index
    @movie = Movie.find_by_name(Muvimeter.fetch_movie_name(10101, params[:url]))
    @host = request.env["HTTP_HOST"]
    puts @host
    if params[:code] == "10101"
      @container = "ctl00_MainContent_mainProgInnerTitle"
    end
    respond_to do |format|
        format.js
        format.html
    end and return  
  end

  def create_whatsonindia_widget
    @movie = Movie.find_by_name(Muvimeter.fetch_movie_name(10101, params[:url]))
    @host = request.env["HTTP_HOST"]
    if params[:code] == "10101"
      @container = "ctl00_MainContent_mainProgInnerTitle"
    end
    a = render_to_string(:partial => 'create_whatsonindia_widget').delete!("\n")
    #render(:text => "document.write(\"" + a + "\");")
    render(:text => 'try{document.getElementById("'"#{@container}"'").innerHTML += "'+ a + '";document.getElementById("'"#{@container}"'").parentNode.style.height = "100px";}catch(E){}')
  end

  def create_msn_widget
    muvi = []
    result_array = {}
    total_name_list = Rails.cache.fetch('msn_widget_cache'){Movie.where("language = 'Hindi' and release_date <= '#{Date.today}' and muvimeter != 0").select("id, name, poster_file_name, muvimeter as meter, permalink").order("release_date desc nulls last, name ASC").find(:all, :limit => 5)}
    total_name_list.each do |m|
      muvi << {:image => m.banner_image_thumb, :host => "http://#{request.env["HTTP_HOST"]}", :name => m.name, :meter => m.meter, :link => m.permalink, :divid => params[:divid]}
    end
    result_array['items'] = muvi
    render :text => "jsonpcallback('#{result_array.to_json}')"
  end


  def create_muvi_widget
    @movie_list = []
    @result_array = []
    total_name_list = Movie.where("language = 'Hindi' and release_date <= '#{Date.today}' and muvimeter != 0").select("id, name, poster_file_name, muvimeter as meter, permalink").order("release_date desc nulls last, name ASC").find(:all, :limit => 5)

    total_name_list.each do |m|
      @movie_list << {:image => m.banner_image_thumb, :name => m.name, :meter => m.meter, :link => m.permalink}
    end
    a = render_to_string(:partial => 'create_muvi_widget').delete!("\n")
    render(:text => "document.write(\"" + a + "\");")
  end


  def create_muvi_widget_nolink
    @movie_list = []
    @result_array = []
    total_name_list = Movie.where("language = 'Hindi' and release_date <= '#{Date.today}' and muvimeter != 0").select("id, name, poster_file_name, muvimeter as meter, permalink").order("release_date desc nulls last, name ASC").find(:all, :limit => 5)

    total_name_list.each do |m|
      @movie_list << {:image => m.banner_image_thumb, :name => m.name, :meter => m.meter, :link => m.permalink}
    end
    a = render_to_string(:partial => 'create_muvi_widget_nolink').delete!("\n")
    render(:text => "document.write(\"" + a + "\");")
  end


  def create_msn_widget_old
    total_name_list = Rails.cache.fetch('msn_widget_cache'){Movie.where("language = 'Hindi' and release_date <= '#{Date.today}' and muvimeter != 0").select("id, name, poster_file_name, muvimeter as meter, permalink as link").order("release_date desc nulls last, name ASC").find(:all, :limit => 5)}
    total_name_list.each do |m|
      m["image"] = m.banner_image_thumb
      m["host"] = "http://#{request.env["HTTP_HOST"]}"
    end
    @movie_list = total_name_list
    #respond_to do |format|
    #  format.js
    #end and return
    a = render_to_string(:partial => 'create_msn_widget').delete!("\n")
    render(:text => "document.write(\"" + a + "\");")
    #render(:text => 'document.write("' + a + '");')
  end

  def create_indiatimes_widget
    total_name_list = Movie.where("release_date <= '#{Date.today}' and muvimeter != 0").select("id, name, poster_file_name, muvimeter as meter, permalink as link").order("release_date desc nulls last, name ASC").find(:all, :limit => 5)
    total_name_list.each do |m|
      m["image"] = m.banner_image_thumb
      m["host"] = "http://#{request.env["HTTP_HOST"]}"
    end
    @movie_list = total_name_list
    #respond_to do |format|
    #  format.js
    #end and return
    a = render_to_string(:partial => 'create_indiatimes_widget').delete!("\n")
    render(:text => "document.write(\"" + a + "\");")
  end

end
