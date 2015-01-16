class HollywoodMovie < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'
  require 'csv'
  set_table_name 'hollywood_movie'

  def self.get_movie_name_and_link_with_loop
    main_url = "http://www.themoviedb.org/movie"
    i = 36997
    while i < 100000
       begin
         html  = Nokogiri::HTML(open("#{main_url}/#{i}"))
         puts html.xpath(".//*[@id='title']/a").text()
         @movie = HollywoodMovie.new()
         @movie.name = html.xpath(".//*[@id='title']/a").text()
         @movie.wiki_url = "#{main_url}/#{i}" 
         @movie.poster_path = html.xpath(".//*[@id='leftCol']/a/img/@src").text()
         @movie.full_text = html.xpath(".//*[@id='movie']").to_s
         @movie.status = false
         @movie.save  
       rescue
         puts "skipping #{main_url}/#{i}"
         puts "---------------------------"
       end
       i += 1
    end
  end 
 
  def self.get_movie_name_and_links
    main_url = "http://www.themoviedb.org/genres"
    html  = Nokogiri::HTML(open(main_url))
    html.xpath(".//*[@id='genre']/ul/li[6 <= position()]/h3/a").each do |genre_link|
       i = 1
       genre = genre_link.text().to_s
       while i < 40  do
         list_link  = "#{genre_link.xpath('./@href')}?page=#{i}"
         puts list_link
         list_html = Nokogiri::HTML(open("#{list_link}"))
         list_html.xpath(".//*[@id='mainCol']/table//tr/td/a[2]").each do |movie_link|
            @is_exist = HollywoodMovie.find_by_name_and_wiki_url(movie_link.text().to_s.strip,movie_link.xpath('./@href').to_s)
            unless @is_exist
              puts "#{movie_link.text()} \t | #{movie_link.xpath('./@href')} "
              
              @movie = HollywoodMovie.new()
              @movie.name = movie_link.text().to_s
              @movie.wiki_url = movie_link.xpath('./@href').to_s
              @movie.genre = genre
              @movie.save
            end
         end
         i += 1
       end
    end
  end
  
  def self.get_movie_details
   movies = HollywoodMovie.where(:status => false).order("id asc")
   ctr = 1
   date_re =  /(\d{4})-(\d{2}-(\d{2}))/
   year_re = /(\d{4})/
   movies.each do |movie|
     begin 
     puts "#{ctr} \t | #{movie.name} \t | #{movie.wiki_url}"
     main_url = movie.wiki_url
     cast_url = "#{movie.wiki_url}/cast"
     main_html = Nokogiri::HTML(movie.full_text)
     cast_html = Nokogiri::HTML(open(cast_url))
     year = year_re.match(cast_html.xpath(".//*[@id='year']").text())
     runtime = cast_html.xpath(".//*[@id='runtime']").text()
     budget = cast_html.xpath(".//*[@id='budget']").text()
     revenue = cast_html.xpath(".//*[@id='revenue']").text()
     languages = cast_html.xpath(".//*[@id='languages']").text()
     release_info = date_re.match(cast_html.xpath(".//*[@id='leftCol']/ul[1]/li[1]/p/br/preceding-sibling::text()").text())
#     overview = main_html.xpath(".//*[@id='overview']").text()
#     tagline = main_html.xpath(".//*[@id='tagline']").text()
     genres = []
     main_html.xpath(".//*[@id='genres']/ul/li/a").each do |genre|
       genres << genre.text()
     end
    
     #Crew collection
     cast_html.xpath(".//*[@class='crew']//tr").each do |crew|
       job = crew.xpath("*[@class='job']").text().to_s.strip
       name =  crew.xpath("*[@class='person']//a").text().to_s
       name_url = crew.xpath("*[@class='person']//a/@href").to_s
       puts "#{job} \t | #{name} \t | #{name_url}"
       @movie_star = HollywoodMovieStar.new()
       @movie_star.movie_id = movie.id
       @movie_star.movie_name= movie.name
       @movie_star.name = name.strip
       @movie_star.wiki_url = name_url
       @movie_star.cast_type = job
       @movie_star.save
     end
      
     # Cast collection
     cast_html.xpath(".//*[@id='castTable']//tr").each do |cast|
       cast_poster_path  = cast.xpath("*[@class='profile']//a/img/@src").to_s.gsub("45", "185")
       cast_name =  cast.xpath("*[@class='person']//a").text().to_s
       cast_url = cast.xpath("*[@class='person']//a/@href").to_s
       cast_role =  cast.xpath("*[@class='character']//span").text().to_s
       puts "#{cast_name} \t | #{cast_url} \t | #{cast_role} \t | #{cast_poster_path}"
       @movie_star = HollywoodMovieStar.new()
       @movie_star.movie_id = movie.id
       @movie_star.movie_name= movie.name
       @movie_star.name = cast_name.strip
       @movie_star.wiki_url = cast_url
       @movie_star.cast_type = 'Actor'
       @movie_star.cast_role = cast_role
       @movie_star.poster_path = cast_poster_path
       @movie_star.save
     end    
     movie.year = year
     movie.running_time = runtime
     movie.budget = budget
     movie.revenue = revenue
     movie.language = languages
     movie.release_date = release_info
     movie.full_text = main_html
     movie.genre = genres
     movie.status = true
     movie.save     
     ctr += 1
     rescue
       puts "skipped \t | #{movie.name}"
     end
   end
  end

  def self.import_hollywood_movie
    allmovies = HollywoodMovie.find(:all, :conditions => ["import_status = false"], :order => 'id')
    ctr = 1
    allmovies.each do |movie|
      if movie.name.force_encoding("UTF-8").ascii_only?
      movie_name = movie.name.strip
      movie_release_date = movie.release_date
      movie_language = 'english'
      movie_running_time = movie.running_time
      movie_budget = movie.budget
      movie_poster_path = movie.poster_path
      movie_wiki_url = movie.wiki_url
      begin
      new_movie = Movie.new
      new_movie.name = movie_name
      new_movie.runtime = movie_running_time
      new_movie.language = movie_language
      new_movie.release_date = movie_release_date
      new_movie.estimated_budget = movie_budget
      new_movie.wiki_link = movie_wiki_url
      new_movie.save
      # add poster
      unless movie_poster_path.blank?
        @poster = Poster.new(:poster_remote_url => movie_poster_path, :name => movie_name, :rank => 1)
        @poster.save
        tagname = Tag.where("lower(name) = ?", movie_name.downcase.strip)
        if tagname.blank?
          @tag = Tag.new
          @tag.id = Tag.last.id + 1
          @tag.name = movie_name

          @tag.save
          @tag_id = @tag.id
        else
          @tag_id = tagname[0].id
        end
        ActiveRecord::Base.connection.execute("SELECT setval('tags_id_seq',#{@tag_id})")
        @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => new_movie.id,:tagger_type => 'Movie', :context =>'tags')
        @tagging.save
        @tagging = Tagging.new(:tag_id => 331, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => 'poster', :context =>'tags')
        @tagging.save
      end
      # add cast
      HollywoodMovieStar.add_cast(movie.id,new_movie.id)
      puts "#{ctr} | #{movie.name} | #{movie.release_date} | #{movie_poster_path}"
      movie.import_status = true
      movie.save
      ctr += 1
      rescue
      end
      end
    end
  end
  def self.remove_erotics
    erotics = HollywoodMovie.where(['genre ilike ?', '%Erotic%']).order('id')
    ctr = 1
    erotics.each do |eroitc|
      puts eroitc.name
      puts eroitc.wiki_url
      mv = Movie.find_by_wiki_link(eroitc.wiki_url)
      unless mv.nil?
        puts eroitc.name
        puts mv.name
        puts ctr
        ctr += 1
        puts "--------------------------"

        puts mv.delete
      end
    end
  end
  def self.remove_duplicates
    hindi = HollywoodMovie.where(['language ilike ?', '%hi%']).order('id')
    hindi.each do |hi|
      mv = Movie.where(:name => hi.name)
      ctr = 1
      if mv.size > 1 
        mv_2 = Movie.find(:all, :conditions => ["name = ? and language like ?",hi.name, 'English'])
        if mv_2.size == 1
        mv_2.each do |m|
          m.delete
          puts  "#{ctr} | #{m.id} | #{m.name} | #{m.language} | #{m.release_date} #{hi.release_date}"
          ctr = ctr + 1
        end
        end
      end
    end
  end
  def self.remove_d_duplicate
     hindi = HollywoodMovie.where(['language ilike ?', '%te%']).order('id')
     ctr = 1
     hindi.each do |hi|
        mv_hi = Movie.find(:all, :conditions => ["name = ? and language = ? and release_date = ?",hi.name, 'Telugu', hi.release_date])
        mv_en = Movie.find(:all, :conditions => ["name = ? and language = ? and release_date = ?",hi.name, 'English', hi.release_date])
        if mv_hi.size + mv_en.size > 1
        #if mv_en.size > 0 and mv_hi.size > 0
          #if hi.language == 'te'
           # puts "------------"
            mv_en.each do |en|
               #en.delete
            #   puts "#{en.name} - #{en.id} - #{en.language}"
            end
            #puts "------------"
            puts  "#{ctr} - #{mv_hi.size} - #{mv_en.size} - #{hi.name} - #{hi.release_date} - #{hi.language} - #{hi.wiki_url} "
            ctr += 1
          #end
        #end
        end
     end
  end

  def self.clean_hollywood_movie_cast
    ctr = 1
    hollywood = Movie.find(:all , :conditions => ["language = 'English' and id > 17000 and id <= 18000"])
    hollywood.each do |movie|
      puts "#{ctr} #{movie.name}  #{movie.wiki_link}"
      puts movie
      ctr = ctr + 1
      break
    end
  end
  def self.hollymovie_cast
    hollywood = Movie.find(:all , :conditions => ["language = 'English' and id > 62000"], :order => 'id')
    ctr = 1
    CSV.open("#{RAILS_ROOT}/public/new_celebs.csv", "a+") do |csv|
      hollywood.each do |movie|
        if !movie.wiki_link.blank? and  movie.wiki_link =~ /www.themoviedb.org/
        puts "#{ctr} #{movie.id} #{movie.name} #{movie.wiki_link}"
        begin
        cast_url = "#{movie.wiki_link}/cast"
        cast_html = Nokogiri::HTML(open(cast_url))
        order = 1
        cast_html.xpath(".//*[@id='castTable']//tr").each do |cast|
          cast_name =  cast.xpath("*[@class='person']//a").text().to_s
          cast_url = cast.xpath("*[@class='person']//a/@href").to_s
          cast_role =  cast.xpath("*[@class='character']//span").text().to_s.gsub("'","")
          if cast_name.force_encoding("UTF-8").ascii_only?
            celeb = Celebrity.find_by_name(cast_name)
            if celeb.blank?
              new_celeb = Celebrity.new
              new_celeb.name = cast_name
              new_celeb.save
              celeb_id = new_celeb.id
              new_line = [celeb_id, cast_name]
              csv << new_line
            else 
              celeb_id = celeb.id
            end
            muvi_cast = MuviCast.new
            muvi_cast.movie_id = movie.id
            muvi_cast.cast_type = 'actor'
            muvi_cast.role_name = cast_role
            muvi_cast.celebrity_id = celeb_id
            muvi_cast.person_priority = order
            muvi_cast.save
            order = order + 1
          end
        end
        cast_html.xpath(".//*[@class='crew']//tr").each do |crew|
          crew_job = crew.xpath("*[@class='job']").text().to_s.strip
          crew_name =  crew.xpath("*[@class='person']//a").text().to_s
          name_url = crew.xpath("*[@class='person']//a/@href").to_s
          if crew_name.force_encoding("UTF-8").ascii_only?
            order = order + 1
            celeb = Celebrity.find_by_name(crew_name)
            if celeb.blank?
              new_celeb = Celebrity.new
              new_celeb.name = crew_name
              new_celeb.save
              celeb_id = new_celeb.id
              new_line = [celeb_id, crew_name]
              csv << new_line
            else
              celeb_id = celeb.id
            end
            muvi_cast = MuviCast.new
            muvi_cast.movie_id = movie.id
            muvi_cast.cast_type = crew_job
            muvi_cast.celebrity_id = celeb_id
            muvi_cast.person_priority = order
            muvi_cast.save
   #        puts "#{order} #{crew_job} \t | #{crew_name}"
          end
        end
        ctr = ctr + 1
        rescue
          puts "skipped #{movie.name}"
        end   
        end
     end
   end
 end
 def self.import_cast
    hollywood = Movie.find(:all , :conditions => ["language = 'English' and id > 62000"], :order => 'id')
    ctr = 1
    hollywood.each do |movie|
      MovieCast.where(:movie_id => movie.id).delete_all
      MuviCast.where(:movie_id => movie.id).order(:person_priority).each do |muvicast|
        muvi_cast = MovieCast.new
        muvi_cast.movie_id = movie.id
        muvi_cast.cast_type = muvicast.cast_type
        muvi_cast.role_name = muvicast.role_name
        muvi_cast.celebrity_id = muvicast.celebrity_id
        muvi_cast.person_priority = muvicast.person_priority
        muvi_cast.save
      end
      puts "#{movie.id} #{movie.name}"
    end 
 end


  def self.update_movie_overview
    main_url = "http://www.themoviedb.org/movie"
    ctr = 1
    movie = HollywoodMovie.where("overview IS NOT NULL and is_done = 0").order('id desc').find(:all)
    movie.each do |movie|
      begin
        #movie_html = Nokogiri::HTML(open("#{main_url}/#{movie.id}"))
 	chk_movie = Movie.find_by_name("#{movie.name}")
        unless chk_movie.blank?

		movie_html = Nokogiri::HTML(open("#{movie.wiki_url}"))
	        overview = movie_html.xpath(".//*[@id='mainCol']/p[@id= 'overview']").text()

        	#HollywoodMovie.where(:wiki_url => movie.wiki_url).each do |s|
	        #  if s.overview.blank?
	        #   s.update_attributes(:overview => overview)
	        #  end
	        #end
        	movie.update_attributes(:overview => overview)
		movie.update_attributes(:is_done => 1)

		chk_movie.update_attributes(:story => overview)
		puts "@@@@@@@@@@@@@@@@@@@@@"
		puts movie.name
		puts movie.id
	end
      rescue
        puts "skipped #{movie.id}"
        puts movie.wiki_url
      end
      ctr += 1
    end
  end

end
