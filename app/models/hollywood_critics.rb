class HollywoodCritics < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'
  require 'csv'    
  set_table_name 'hollywood_critics'
 
  def self.get_critics
   ctr = 1
   ('a'..'z').each do |l|
     url = "http://www.rottentomatoes.com/critics/authors.php?view=#{l}"
     puts url
     html  = Nokogiri::HTML(open(url))
     no_of_pages =  html.xpath(".//*[@id='authors']//div[@class='fr']").first.text.strip.gsub(/\r/,"").gsub(/\n/,"").gsub(/\s+/, ' ').chomp.gsub("(1-50 of ", "").gsub(") Next",'')
     no_of_page =  (no_of_pages.to_i/ 50).ceil + 1
     i = 1
     while i <= no_of_page do
        page_html = Nokogiri::HTML(open("http://www.rottentomatoes.com/critics/authors.php?view=#{l}&page=#{i}"))
        puts "http://www.rottentomatoes.com/critics/authors.php?view=#{l}&page=#{i}"
        page_html.xpath(".//*[@class='onlyCol']//a").each do |critic_url| 
           if critic_url.text.force_encoding("UTF-8").ascii_only?
             is_exist = HollywoodCritics.where(:name => critic_url.text.strip)           
             if is_exist.blank?
                 critics = HollywoodCritics.new
                 critics.name = critic_url.text.strip
                 critics.url = "http://www.rottentomatoes.com#{critic_url.xpath("./@href").text.strip}"
                 critics.save
             end
           end
        end
        i += 1
     end
     ctr = ctr + 1
   end
  end
  def self.get_critics_organisation
   critics = HollywoodCritics.where(:status => false).order(:id)
   critics.each do |critic|
    begin 
    critic_org = Nokogiri::HTML(open("#{critic.url}"))
    puts critic.id
    puts critic.name 
    puts critic.url
    critic.organization =  critic_org.xpath(".//*[@id='criticsSidebar_main']/div[2]/div/div[2]/dl/dd[last()]").text.strip.gsub(/\r/,"").gsub(/\n/,"").gsub(/\s+/, " ").chomp
    critic.image = critic_org.xpath(".//*[@id='criticsSidebar_main']//img/@src")
    critic.status = true
    critic.save
    rescue
     puts "----------------------"
     puts critic.name
     puts critic.url
     puts "----------------------"
    end
   end
  end
   
  def self.get_movie_rotten
#    url = "http://www.rottentomatoes.com/movie/in-theaters/?page=2"
    url = "http://www.rottentomatoes.com/movie/in-theaters/?page=1"
    i = 1980
    while i < 2013  do
      url = "http://www.rottentomatoes.com/top/bestofrt/?year=#{i}"
      html  = Nokogiri::HTML(open(url))
      html.xpath(".//*[@id='top_movies_main']/div[2]/table/tbody/tr//td[3]/a").each do |movie|
        puts movie
        if movie.text.force_encoding("UTF-8").ascii_only?
          movie_name = movie.text.strip.gsub("(#{i})","").strip
          movie_link = movie.xpath("./@href").text.strip
          movie = Movie.where("name = ? and EXTRACT(YEAR FROM release_date) = #{i}", movie_name)
          unless movie.blank?
            critic_url = "http://www.rottentomatoes.com#{movie_link}reviews/?type=top_critics"
            critics_html = Nokogiri::HTML(open("#{critic_url}")) 
            critics_html.xpath(".//*[@id='reviews']/div[2]/div").each do |divs|
              critics_name =  divs.xpath("div/div[1]/strong/a").text.strip
          
              review_description = divs.xpath("div/div[3]/p[1]").text.strip
              review_link =  divs.xpath("div/div[3]/p[2]/a[1]/@href").text.strip
              if divs.xpath("div/div[contains(@class,'tmeterfield')]/div[contains(@class,'fresh')]").size == 1
                review_score = 4
              else 
                review_score = 2 
              end
              if critics_name.force_encoding("UTF-8").ascii_only?
                critic = FilmCritic.find_by_name(critics_name)
                if critic
                  if review_description.force_encoding("UTF-8").ascii_only?
                  unless review_description.blank?
                    cr = CriticsReview.where(:movie_id => movie[0].id , :film_critic_id => critic.id)
                    if cr.blank? 
                      critic_review = CriticsReview.new
                      critic_review.rating = review_score
                      critic_review.summary = review_description
                      critic_review.link = review_link
                      critic_review.movie_id = movie[0].id
                      critic_review.film_critic_id = critic.id
                      critic_review.save
                      puts movie[0].name
                    end
                  end
                  end
                end
              end
            end
          end
        end
      end
      puts url
      i += 1
    end
  end
  def self.import_critics
    critics = HollywoodCritics.where(:status => true, :import_status => false).order('id')
    critics.each do |critic|
      puts critic.name
      puts critic.id
      is_exist = FilmCritic.where(:name => critic.name)
      if is_exist.blank?
         @user = User.new
         @user.email = "critics#{critic.id}@muvi.com"
         @user.password = "muvicritics"
         @user.is_registered = false
         @user.save! 
         @film_critic = FilmCritic.new
         @film_critic.name = critic.name
         @film_critic.organization = critic.organization
         unless critic.image.blank?
           source_url = critic.image
           io = open(URI.parse(source_url).to_s)
           def io.original_filename; base_uri.path.split('/').last; end 
           @film_critic.thumbnail_image = io.original_filename.blank? ? nil : io
         end
         @film_critic.user_id = @user.id
         @film_critic.save
         puts critic.id
         puts critic.name
         critic.import_status = true
         critic.save
      end
    end
  end

  def self.import_users
    @file = "#{RAILS_ROOT}/public/data/Previous-Users.csv"
    csv_text = File.read(@file)
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
       begin 
       @user = User.new
       @user.email = row[1]
       @user.display_name = row[0]
       @user.password = "muvitest"
       @user.save!
         puts row[1]
       rescue
         puts "skipped #{row[1]}"
       end
    end
  end

  def self.get_celeb_movie_count
    ctr = 1
    Celebrity.where("id > 40000 and id <= 70000").each do |celeb|
      if celeb.movie_casts.size == 0
        puts "#{celeb.name} #{celeb.movie_casts.size}"
        celeb.delete
      end
      ctr = ctr + 1
    end
  end
  def self.get_movie_cast_count
   ctr = 1
   movies = Movie.where("id > 79000")
   movies.each do |movie|
     if movie.movie_casts.size == 0 
       puts "#{ctr} #{movie.name} #{movie.movie_casts.size} #{movie.movie_casts.count}"
       movie.delete
     end
     ctr = ctr + 1
   end
  end
  def self.get_movie_review_count
   ctr = 1
   movies = Movie.where("language = 'English'").order("id")
   CSV.open("#{RAILS_ROOT}/public/critics_review.csv", "a+") do |csv|
     movies.each do |movie|
       if movie.critics_reviews.size > 0
         puts "#{ctr} #{movie.name} #{movie.critics_reviews.count} #{movie.critics_reviews.size}"
         csv << [ctr, movie.name, movie.critics_reviews.count]
       end
       ctr = ctr + 1
     end
   end
  end
  def self.clean_movies
   ctr = 1
   HollywoodMovie.where("genre = '[\"Short\"]'").each do |mv|
     begin
     puts "#{ctr} #{mv.name} #{mv.wiki_url}"
     Movie.where("name = ? and wiki_link = ?", mv.name , mv.wiki_url).first.delete
     ctr = ctr + 1
     rescue
       puts "NOT #{mv.name}"
     end
   end
  end
end
