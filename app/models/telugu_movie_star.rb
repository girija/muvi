class TeluguMovieStar < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'

  set_table_name 'telugu_movie_star_data'

  def self.add_cast(telugu_movie_id, movie_id)
    cnt = 0
    movie_star = TeluguMovieStar.where(:movie_id => telugu_movie_id).order("id desc")
    movie_star.each do |star|
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
        celeb = Celebrity.new
        celeb.name = star.name
        celeb.save
        mov_cast = MovieCast.new
        mov_cast.movie_id = movie_id
        mov_cast.cast_type = star.cast_type.downcase
        mov_cast.role_name = star.cast_role
        mov_cast.celebrity_id = celeb.id
        mov_cast.person_priority = (cnt + 1)
        mov_cast.save
      end
    end
  end

end
