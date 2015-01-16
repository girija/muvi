module UtilityHelper
  def self.camelcase_to_spaced(word)
    word.gsub(/([A-Z])/, " \\1").strip
  end
 
  def self.get_actors(movie, limit = 2)
   @actors = []
    movie.movie_casts.each do |cast|
      case cast.cast_type
        when 'actor' then @actors << cast.celebrity.id
      end
    end
    return @actors
  end
end
