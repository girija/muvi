class HollywoodMovieStar < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'
  set_table_name 'hollywood_movie_star'

  def self.update_star_data
    ctr = 1
    main_url = "http://www.themoviedb.org"
    date_re =  /(\d{4})-(\d{2}-(\d{2}))/
    stars = HollywoodMovieStar.where(:status => false).order('id')
    stars.each do |star|
      begin 
        puts "#{star.id} \t | #{ctr} \t | #{main_url}#{star.wiki_url}"
        star_html = Nokogiri::HTML(open("#{main_url}#{star.wiki_url}"))
        birth_day = date_re.match(star_html.xpath(".//*[@id='leftCol']/p[contains(.,'Birthday')]").text())
        poster_path = star_html.xpath(".//*[@id='leftCol']/a/img/@src").text()
        HollywoodMovieStar.where(:wiki_url => star.wiki_url, :status => false).each do |s|
          if s.birth_date.blank?
            s.update_attributes(:birth_date => birth_day)
          end
          if s.poster_path.blank?
           s.update_attributes(:poster_path => poster_path)
          end
          s.update_attributes(:status => true)
        end
      rescue
         puts "skipped #{star.id}"
      end
      ctr += 1
    end
  end
  def self.add_cast(hollywood_movie_id, movie_id)
    cnt = 0
    movie_star = HollywoodMovieStar.where(:movie_id => hollywood_movie_id)
    movie_star.each do |star|
      if star.name.force_encoding("UTF-8").ascii_only?
        begin
          celeb = Celebrity.where("lower(name) = ?", star.name.downcase).first
          unless celeb.blank?
            ## Add movie_cast
            mov_cast = MovieCast.new
            mov_cast.movie_id = movie_id
            mov_cast.cast_type = star.cast_type.downcase
            mov_cast.role_name = star.cast_role
            mov_cast.celebrity_id = celeb.id
            mov_cast.person_priority = (cnt + 1)
            mov_cast.save
          else
            #create celeb
            begin
              celeb = Celebrity.new
              celeb.name = star.name
              celeb.birthdate = star.birth_date
              celeb.save
              mov_cast = MovieCast.new
              mov_cast.movie_id = movie_id
              mov_cast.cast_type = star.cast_type.downcase
              mov_cast.role_name = star.cast_role
              mov_cast.celebrity_id = celeb.id
              mov_cast.person_priority = (cnt + 1)
              mov_cast.save
            rescue
              puts "skipped #{star.name}"
            end
          end
        rescue
          puts "skipped #{star.name}"
        end
        cnt += 1
      end
    end
  end
  def self.add_posters_to_stars
    ctr = 1
    celebs = Celebrity.where("language is null").order('id asc')
    celebs.each do |celeb|
      hollywood_star = HollywoodMovieStar.where("name = ?",celeb.name).first
      if hollywood_star
        puts "#{ctr} | #{celeb.id}  | #{celeb.name}"
        if hollywood_star.poster_path.to_s.strip.length > 0
          puts "#{ctr} | #{celeb.id}  | #{celeb.name} | #{hollywood_star.poster_path}"
          @poster = Poster.new(:poster_remote_url => hollywood_star.poster_path, :name => celeb.name, :rank => 1)
          @poster.save
          tagname = Tag.where("lower(name) = ?", celeb.name.downcase)
          if tagname.blank?
            @tag = Tag.new
            @tag.id = Tag.last.id + 1
            @tag.name =  celeb.name
            @tag.save
            @tag_id = @tag.id
          else
            @tag_id = tagname[0].id
          end
          @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => celeb.id,:tagger_type => 'Celebrity', :context =>'tags')
          @tagging.save
          @tagging = Tagging.new(:tag_id => 343, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => 'profilepic', :context =>'tags')
          @tagging.save
          ctr += 1
        end
        celeb.language = 'English'
        celeb.save
      end
    end
  end


  def self.update_star_bio
    ctr = 1
    main_url = "http://www.themoviedb.org"
    stars = HollywoodMovieStar.where("bio IS NULL").order('id desc').find(:all) #, :limit => 1)
    stars.each do |star|
      begin
        star_html = Nokogiri::HTML(open("#{main_url}#{star.wiki_url}"))
        #star_html = Nokogiri::HTML(open("http://www.themoviedb.org/person/8784-daniel-craig"))
        bio = star_html.xpath(".//*[@id='mainCol']/p[@id= 'biography']").text()
        bio = bio.gsub(/\([^)]+\)\s+/,'')

        puts "+++++++++++++++"
        bio_1 = bio.split(".")
        if bio_1.size > 0
          if !bio_1[0].index("Wikipedia").nil?
            new_bio = bio.gsub(bio_1[0]+".", "")
          else
            new_bio = bio
          end
        end
        puts "#################"
        bio_2 = new_bio.split(".")
        if bio_2.size > 0
          if !bio_2[bio_2.size.to_i - 1].index("Wikipedia").nil?
            new_bio_1  = new_bio.gsub(bio_2[bio_2.size.to_i - 1], "") 
          else
            new_bio_1 = new_bio
          end
        end

        # remove the extra . from the end of the bio
        new_bio_1 = new_bio_1.gsub("..", ".")


        HollywoodMovieStar.where(:wiki_url => star.wiki_url).each do |s|
          if s.bio.blank?
           s.update_attributes(:bio => new_bio_1)
           puts star.id
           puts star.wiki_url
           puts "_____________"
          end
        end
      rescue Exception => exc
         puts exc.message
         puts "skipped #{star.id}"
      end
      ctr += 1
    end
  end

end
