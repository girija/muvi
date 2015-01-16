class ListOfMovie < ActiveRecord::Base
  include DisplayHelper
  acts_as_followable
  attr_accessible :pass_lists, :discovery_lists
  def self.add_update_list(user_id, movie_id, list_type)
    in_list =  ListOfMovie.find_by_user_id(user_id)
    movie = Movie.find_by_id(movie_id)
    user = UserProfile.find_by_user_id(user_id)
    @seen_lists = []
    @wanna_see_lists = []
    @wanna_see = []
    if in_list.nil?
      @list_json = {:published => Date.today, :actor => {:url => "", :objectType => 'user', :id => user_id, :image => {:url => ''}, :displayName => user.display_name}, :verb => "add to list", :object => {:url => "/movies/#{movie.permalink}", :objectType => "movie", :id => "#{movie.id}", :image => {:url => "#{movie.banner_image}"}, :displayName => movie.name}, :target => list_type}
      if list_type == 'wanna see'
        @wanna_see_lists << @list_json 
      elsif list_type == 'seen it'
        @seen_lists << @list_json
      end
      #ListOfMovie.add_to_list(list_type, @list_json, user_id)
      list = ListOfMovie.new 
      list.user_id = user_id
      list.wanna_see_lists = @wanna_see_lists.to_json
      list.discovery_lists = list.discovery_lists.gsub("[","").gsub("]","").split(",").map(&:to_i).select{|v| v != movie_id.to_i}.to_json if list.discovery_lists
      list.seen_lists = @seen_lists.to_json
      list.save
    else
      @list_json = {:published => Date.today, :actor => {:url => "", :objectType => 'user', :id => user_id, :image => {:url => ''}, :displayName => user.display_name}, :verb => "add to list", :object => {:url => "/movies/#{movie.permalink}", :objectType => "movie", :id => "#{movie.id}", :image => {:url => "#{movie.banner_image_thumb}"}, :displayName => movie.name}, :target => list_type}
      #ListOfMovie.add_to_list(list_type, @list_json, user_id)

      if list_type == 'wanna see'
        @wanna_see_lists  = ActiveSupport::JSON.decode(in_list.wanna_see_lists) if !in_list.wanna_see_lists.nil?
        n_wsee = true
        if @wanna_see_lists
          @wanna_see_lists.each do |wsee|
            if wsee && wsee["object"]
              if wsee["object"]["id"] == movie.id.to_s
                n_wsee = false
                return
              end
            end
          end
        end
        if n_wsee
          @wanna_see_lists << @list_json
          in_list.wanna_see_lists = @wanna_see_lists.to_json
        end
      elsif list_type == 'seen it'
        @seen_lists  = ActiveSupport::JSON.decode(in_list.seen_lists) if !in_list.seen_lists.nil?
        n_seen = true
        @seen_lists.each do |seen|
          if seen && seen["object"]
            if seen["object"]["id"] == movie.id.to_s
              n_seen = false
              return
            end
          end
        end
        if n_seen
          @seen_lists << @list_json
          in_list.seen_lists = @seen_lists.to_json
          wanna_see_json = ActiveSupport::JSON.decode(in_list.wanna_see_lists)
          if wanna_see_json
            wanna_see_json.each do |wanna_see|
              unless wanna_see.nil?
                if wanna_see["object"]["id"] != movie_id
                  @wanna_see  << wanna_see
                end
              end
            end
          end
          in_list.wanna_see_lists = @wanna_see.to_json
        end
      end
      in_list.discovery_lists = in_list.discovery_lists.gsub("[","").gsub("]","").split(",").map(&:to_i).select{|v| v.to_i != movie_id.to_i}.to_json if in_list.discovery_lists
      in_list.save

    end

    ########## Add an activity
      if list_type == "wanna see"
        act_type = "want to see"
      elsif list_type  == "seen it"
        act_type = "saw"
      end

        l = ActiveSupport::JSON.decode(@list_json.to_json)
        act = AllActivity.new
        act.user_id = user_id
        act.movie_id = movie.id
        act.activity_type = act_type
        act.activity = AllActivity.create_json(l)
        act.save

      ########## Activity ends

  end

  def self.add_to_list(list_type, list_item, user_id)
    if list_type == 'wanna see'
      list_type = 'wanna_see'
    elsif list_type == 'seen it'
      list_type = 'seen_it'
    end
    #ApplicationHelper.broadcast("/home/index/#{list_type}/#{user_id}", list_item)

  end

  def self.wanna_see_to_seen(user_id, movie_id)
    @wanna_see = []
    list =  ListOfMovie.find_by_user_id(user_id)
    wanna_see_json = ActiveSupport::JSON.decode(list.wanna_see_lists) 
    wanna_see_json.each do |wanna_see|
      unless wanna_see.nil?
        if wanna_see["object"]["id"] == movie_id
          wanna_see["target"] = "seen it"
          @move_to_seen = wanna_see
        else
          @wanna_see  << wanna_see  
        end
      end
    end
    unless list.seen_lists.blank?
      @seen_json = ActiveSupport::JSON.decode(list.seen_lists)
    else
      @seen_json = []
    end
    @seen_json << @move_to_seen
    list.wanna_see_lists = @wanna_see.to_json
    list.seen_lists = @seen_json.to_json 
    list.save

    #uc = UserConnection.find_by_user_id(user_id)
    #unless uc.blank?
    #  @conn = ActiveSupport::JSON.decode(uc.connections)
    #  unless @conn.blank?
    #    @conn.each do |conn|
    #      AllActivity.check_for_wanna_notification(conn)
    #      AllActivity.check_for_seen_notification(conn)
    #    end
    #  end
    #end

    #puts user_id
    #u = AllActivity.select("user_id").where("user_id NOT IN (#{user_id})").find(:all, :group => "user_id")
    #unless u.blank?
    #  u.each do |c|
    #    conn = c.user_id
    #    puts conn
    #    AllActivity.delay.check_for_wanna_notification(conn)
    #    AllActivity.delay.check_for_seen_notification(conn)
    #  end
    #end

    ########## Add an activity

    l = ActiveSupport::JSON.decode(@move_to_seen.to_json)
    act = AllActivity.new
    act.user_id = user_id
    act.movie_id = movie_id
    act.activity_type = "saw"
    act.activity = AllActivity.create_json(l)
    act.save

    ########## Add an activity ends

  end

  def self.update_discovery_all
    users = User.where(:last_sign_in_at => 1.year.ago..Time.now) 
    users.each do |user|
      update_discovery(user.id)
    end
  end
  def self.update_discovery(user_id)
    @seen_movies = []
    @wanna_see_movies = []
    @my_wanna_see_movies = []
    @my_seen_movies = [] 
    @my_pass_movies = []
    @random_movies = []
    @all_movies = []
  
    my_movies = ListOfMovie.where(:user_id => user_id).first
    unless my_movies.nil?
      unless my_movies.wanna_see_lists.nil?
        my_wanna_see = ActiveSupport::JSON.decode(my_movies.wanna_see_lists)
        my_wanna_see.each do |ws|
          @my_wanna_see_movies <<  ws["object"]["id"].to_i
        end
      end
      unless my_movies.seen_lists.nil?
        my_seen = ActiveSupport::JSON.decode(my_movies.seen_lists)
        my_seen.each do |s|
        begin
         @my_seen_movies << s["object"]["id"].to_i
        rescue
         puts "Error"
        end
        end
      end
      unless my_movies.pass_lists.nil?
        my_pass = ActiveSupport::JSON.decode(my_movies.pass_lists)
        my_pass.each do |p|
          @my_pass_movies << p
        end
      end
    end
    
    #user_connections =  UserConnection.find_by_user_id(user_id)
    #unless  user_connections.nil?
    #list_of_movies =  ListOfMovie.where("user_id in (?)", user_connections.connections.gsub("[","").gsub("]","").split(",").to_a)
    #list_of_movies.each do |list_of_movie|
    #  wanna_see = ActiveSupport::JSON.decode(list_of_movie.wanna_see_lists) unless list_of_movie.wanna_see_lists.nil?
    #  unless wanna_see.nil?
    #  wanna_see.each do |ws|
    #    unless ws.nil?
    #      @wanna_see_movies <<  ws["object"]["id"].to_i
    #    end
    #  end 
    #  end
    #  seen = ActiveSupport::JSON.decode(list_of_movie.seen_lists) unless list_of_movie.seen_lists.nil?
    #  unless seen.nil?
    #  seen.each do |s|
    #     unless s.nil?
    #       @seen_movies << s["object"]["id"].to_i
    #     end
    #  end
    #  end
    #end
    #end
    @last_quater_movies =  Movie.where(:release_date => 4.months.ago..Time.now, :muvimeter => 60..100)
    @random_movies_recomend = []
    @last_quater_movies.each do |movie|
      @random_movies_recomend << movie.id.to_i
    end 
    #url = "http://ec2-122-248-213-135.ap-southeast-1.compute.amazonaws.com:3000/application/reccomend_list/#{@my_seen_movies + @my_wanna_see_movies}/[]"

    url = "http://54.172.192.84:3000/application/reccommend_list/#{@my_seen_movies + @my_wanna_see_movies}/[]"
    hailo = Addressable::URI.encode(url)
    @list_of_recomendation =  JSON.parse(open(URI::encode("#{hailo}")).read)
    if @list_of_recomendation.blank?
       @list_of_recomendation = @random_movies_recomend
    end    
#    @discovery_movie = @random_movies
#    unless @wanna_see_movies.nil?
#      @discovery_movie += @wanna_see_movies
#    end
#    unless @seen_movies.nil?
#     @discovery_movie += @seen_movies
#    end
#    unless @my_wanna_see_movies.nil?
#      @discovery_movie -= @my_wanna_see_movies
#    end
#    unless @my_seen_movies.nil?
#      @discovery_movie -= @my_seen_movies
#    end
    unless @my_pass_movies
      @discovery_movie -= @my_pass_movies
    end
    in_list =  ListOfMovie.find_by_user_id(user_id)
    if in_list.nil?
      new_list = ListOfMovie.new 
      new_list.user_id = user_id
      new_list.discovery_lists = @list_of_recomendation.uniq.to_json
      new_list.save
    else
      in_list.discovery_lists = @list_of_recomendation.uniq.to_json 
      in_list.save
    end
  end
  def random_100_movies
    
  end
  def self.all_seen_movie_for(user_id, list_type)
   @all_movie_list = []
   @all_movie_list_json = []
   user_list = ListOfMovie.all
   user_list.each do |user|
     unless  user.discovery_lists.blank?
       discovery_list  = ActiveSupport::JSON.decode(user.discovery_lists)
       discovery_list.each do |dl|
         @all_movie_list << dl
       end
     end
   end
   user = UserProfile.find_by_user_id(user_id)
   @all_movie_list.uniq.each do |movie_list|
     movie = Movie.find_by_id(movie_list)
     list_json = {:published => Date.today, :actor => {:url => "", :objectType => 'user', :id => user_id, :image => {:url => ''}, :displayName => user.display_name}, :verb => "add to list", :object => {:url => "movie/#{movie.permalink}", :objectType => "movie", :id => "#{movie.id}", :image => {:url => "#{movie.banner_image}"}, :displayName => movie.name}, :target => list_type}
     @all_movie_list_json << list_json

   end
   in_list =  ListOfMovie.find_by_user_id(user_id)
   if in_list.nil?
     list = ListOfMovie.new
     list.user_id = user_id
     if list_type == 'wanna see'
        list.wanna_see_lists = @all_movie_list_json.to_json
      elsif list_type == 'seen it'
       list.seen_lists = @all_movie_list_json.to_json
      end

     list.save
   else
     if list_type == 'wanna see'
        in_list.wanna_see_lists = @all_movie_list_json.to_json
      elsif list_type == 'seen it'
        in_list.seen_lists = @all_movie_list_json.to_json
      end

     in_list.save
   end
  end
  def self.clean_duplicate
    user_list = ListOfMovie.all
    user_list.each do |ul|
     if !ul.seen_lists.blank?
      s_list  = ActiveSupport::JSON.decode(ul.seen_lists)
      @s_movies = []
      @seen_list = []
      s_list.each do |s|
        unless s.blank?
          unless s["object"].blank?
            if !@s_movies.include?(s["object"]["id"].to_i)
              @s_movies << s["object"]["id"].to_i
              @seen_list << s
            end
          end
        end
      end
      ul.seen_lists  =  @seen_list.to_json
      ul.save
     end

     if  !ul.wanna_see_lists.blank?
       w_s_list  = ActiveSupport::JSON.decode(ul.wanna_see_lists)
       @w_s_movies = []
       @wanna_see_list = []
       w_s_list.each do |ws|
         if !@w_s_movies.include?(ws["object"]["id"].to_i)
           if !@s_movies.include?(ws["object"]["id"].to_i)
             @w_s_movies << ws["object"]["id"].to_i
             @wanna_see_list << ws
           end
         end
       end
       ul.wanna_see_lists  =  @wanna_see_list.to_json
       ul.save
     end
    end
  end
  def self.list_all_movies
    @list_all_movies = []
    @list_all_movies_name = []
    user_list = ListOfMovie.all
    user_list.each do |ul|
      if !ul.discovery_lists.blank?
        dls = ActiveSupport::JSON.decode(ul.discovery_lists)
        dls.each do |dl|
          if !@list_all_movies.include?(dl.to_i)
             @list_all_movies << dl
             movie = Movie.find(dl)
             @list_all_movies_name << movie.name
          end
        end
      end
      if !ul.seen_lists.blank?
        sls = ActiveSupport::JSON.decode(ul.seen_lists)
        sls.each do |sl|
          unless sl.blank?
            unless sl["object"].blank?
              if !@list_all_movies.include?(sl["object"]["id"].to_i)
                @list_all_movies << sl["object"]["id"].to_i
                movie = Movie.find(sl["object"]["id"].to_i)
                @list_all_movies_name << movie.name
              end
            end
          end
        end
      end
      if !ul.wanna_see_lists.blank?
        wls = ActiveSupport::JSON.decode(ul.wanna_see_lists)
        wls.each do |wl|
          unless wl.blank?
            unless wl["object"].blank?
              if !@list_all_movies.include?(wl["object"]["id"].to_i)
                @list_all_movies << wl["object"]["id"].to_i
                movie = Movie.find(wl["object"]["id"].to_i)
                @list_all_movies_name << movie.name
              end
            end
          end
        end
      end

    end
    aFile = File.new("public/mlist.txt", "a+")
    if aFile
     aFile.syswrite(@list_all_movies_name.to_json)
    end
  end

end
