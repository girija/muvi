class Sm < ActiveRecord::Base
  require 'rubygems'
  require 'sitemap_generator' 

  def self.movie_celeb_sitemap
    Sm.create_sm("movie")
    Sm.create_sm("celeb")
  end

  def self.top_filmo_sitemap
    Sm.create_sm("top_ten")
    Sm.create_sm("filmography")
  end

  def self.together_sitemap
    Sm.create_sm("together")
  end

  def self.validate_url(url)
    i_path = ""
    if url.force_encoding("UTF-8").ascii_only? 
      begin
        url = URI.parse(URI.encode(url, "[]").gsub(" ", "%20"))
      rescue
        url = URI.parse(url.gsub(" ", "%20"))
      end
    
      req = Net::HTTP::Get.new(url.path)
      result = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
      if result.code == "200"
        i_path = url
      else
        i_path = "/images/no-image.png"
      end
    else
      i_path = "/images/no-image.png"
     end

    return i_path
  end


  def self.create_sm(type)
    name = type
    path = 'sitemaps'
    condition = ""

    if type == "movie"
      rel = "Movie"
      perma_path = "movies"

    elsif type == "celeb"
      rel = "Celebrity"
      perma_path = "stars"

    elsif type == "together"
      rel = "Celebrity"
      perma_path = "stars" 

    elsif type == "filmography"
      rel = "Celebrity"
      perma_path = "stars"      

    elsif type == "top_ten"
      rel = "TopTen"
      perma_path = "top_ten"      
      condition = "rank != 0"
    end

    SitemapGenerator::Sitemap.default_host = 'http://www.muvi.com'
    SitemapGenerator::Sitemap.sitemaps_path = path
    SitemapGenerator::Sitemap.filename = name
    
    rec = rel.constantize.find(:all, :conditions => ["#{condition}"])
    SitemapGenerator::Sitemap.create do
      rec.each do |r|

        if type == "together"
          co_stars = Celebrity.get_top_costars(r)
          co_stars.each do |costar|
            add "/stars/#{r.permalink}/#{costar.celebrity.to_param}/together"
          end

        elsif type == "filmography"
          add '/'"#{perma_path}"'/'+r.permalink+'/filmography', :changefreq => 'daily', :priority => 0.9
          #img = r.medium_image
          #url = Sm.validate_url("#{POSTER_URL}"+"#{img}")

          #add '/'"#{perma_path}"'/'+r.permalink+'/filmography', :images => [{
          #                   :loc => "#{url}",
          #                  :title => "#{r.name}" }], :changefreq => 'daily', :priority => 0.9

        elsif type == "top_ten"
          add '/'"#{perma_path}"'/'+ r.id.to_s + '/'+ r.name, :changefreq => 'daily', :priority => 0.9

        #elsif type == "movie"
        #  img = r.banner_image_medium
        #  url = Sm.validate_url("#{POSTER_URL}"+"#{img}")
           
        #  add '/'"#{perma_path}"'/'+r.permalink , :images => [{
        #                     :loc => "#{url}",
        #                    :title => "#{r.name}" }], :changefreq => 'daily', :priority => 0.9
        #elsif type == "celeb"
        #  img = r.medium_image
        #  url = Sm.validate_url("#{POSTER_URL}"+"#{img}")

        #  add '/'"#{perma_path}"'/'+r.permalink , :images => [{
        #                     :loc => "#{url}",
        #                    :title => "#{r.name}" }], :changefreq => 'daily', :priority => 0.9

        else
          add '/'"#{perma_path}"'/'+r.permalink, :changefreq => 'daily', :priority => 0.9
        end
      end  
    end
    SitemapGenerator::Sitemap.ping_search_engines

  end

end

