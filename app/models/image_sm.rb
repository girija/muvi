class ImageSm < ActiveRecord::Base
  require 'rubygems'
  require 'sitemap_generator'

  def self.movie_celeb_image_sitemap
    ImageSm.create_image_sm("movie_image")
    ImageSm.create_image_sm("celeb_image")
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


  def self.create_image_sm(type)
    name = type
    path = 'image_sitemaps'
    condition = ""

    if type == "movie_image"
      rel = "Movie"
      context = "poster"

    elsif type == "celeb_image"
      rel = "Celebrity"
      context = "profilepic"
    end

    SitemapGenerator::Sitemap.default_host = 'http://www.muvi.com'
    SitemapGenerator::Sitemap.sitemaps_path = path
    SitemapGenerator::Sitemap.filename = name

    rec = rel.constantize.find(:all, :conditions => ["#{condition}"], :order => ["id desc"])
    SitemapGenerator::Sitemap.create do
      rec.each do |r|
        title = ""
        poster = Tagging.where("t2.taggable_type = 'Poster' and t2.tagger_id='#{r.id}' and t2.tagger_type='#{rel}'").find(:all, :select => ["t2.taggable_id"], :joins => ["inner join taggings t2 on taggings.taggable_id = t2.taggable_id"], :conditions => ["lower(taggings.tagger_type)='#{context}'"], :group => ["t2.taggable_id"])

        unless poster.blank?
          poster.each do |p|
            poster_image = Poster.where("id = #{p.taggable_id}").find(:all, :conditions => ["rank = 1"], :order => ["id desc"])
            unless poster_image.blank?
              title = poster_image[0].name
              unless poster_image[0].poster_file_name.blank?
                img = "#{POSTER_URL}/system/posters/#{poster_image[0].id}/standard/#{poster_image[0].poster_file_name}"
                img_loc = "system/posters/#{poster_image[0].id}/standard/#{poster_image[0].poster_file_name}"
              else
                img = "#{POSTER_URL}/images/no-image.png"    
                img_loc = "images/no-image.png"
              end
              add '/'+img_loc , :images => [{:loc => "#{ImageSm.validate_url(img)}",
                            :title => "#{title}" }], :changefreq => 'daily', :priority => 0.9
            end
          end
        end
      end
    end
    SitemapGenerator::Sitemap.ping_search_engines

  end

end

