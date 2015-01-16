class VideoSm < ActiveRecord::Base
  require 'rubygems'
  require 'sitemap_generator'

  def self.movie_celeb_video_sitemap
    VideoSm.create_video_sm("movie_video")
    #ImageSm.create_image_sm("celeb_video")
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


  def self.create_video_sm(type)
    name = type
    path = 'video_sitemaps'
    condition = ""

    if type == "movie_video"
      rel = "Movie"
      context = "video"

    elsif type == "celeb_vidoe"
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
        video =  Tagging.where("taggable_type = 'Video' and tagger_id = '#{r.id}' and tagger_type = '#{rel}'").find(:all)
        unless video.blank?
          video.each do |p|
            unless p.taggable_id.blank?
              video_image = Video.where("id = #{p.taggable_id}").find(:all, :conditions => ["rank = 1"], :order => ["id desc"])
              unless video_image.blank?
                title = video_image[0].name
                unless video_image[0].trailer_file_name.blank?
                  video = "#{VIDEO_URL}/system/trailers/#{video_image[0].id}/original/#{video_image[0].trailer_file_name}"    
                  video_thumbnail_loc = "#{VIDEO_URL}/system/trailer_thumbnails/#{video_image[0].id}/1.jpg"
                  video_loc = "/movies/#{r.permalink}/video/#{video_image[0].id}"
                 
                  add("#{video_loc}", :video => {
                        :thumbnail_loc => "#{video_thumbnail_loc}",
                        :title => "#{title}",
                        :content_loc => "#{video}"
                  })
                  puts "#{r.id} ----  #{r.name}"
                end
              end
            end
          end
        end
      end
    end
    SitemapGenerator::Sitemap.ping_search_engines

  end

end

