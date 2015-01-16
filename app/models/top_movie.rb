class TopMovie < ActiveRecord::Base

  def self.top_100_movies
    movies = Movie.select("id").order("RANDOM()").limit(100)
    @movie_ids = []
    movies.each do |movie|
      @movie_ids << movie.id
    end
    TopMovie.create(:movie_ids => @movie_ids)
  end
end
