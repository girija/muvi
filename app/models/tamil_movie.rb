class TamilMovie < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'
  set_table_name 'tamil_movie_data'

  def self.import_tamil_movie
    movies = TamilMovie.find(:all, :conditions => ["import_status = false"], :order => ["id asc"])
    ctr = 1
    movies.each do |movie|  
      movie_name = movie.name.strip
      movie_release_date_s = movie.release_date_s
      movie_release_date = movie.release_date
      movie_language = 'Tamil'
      movie_box_office = movie.box_office
      movie_running_time = movie.running_time
      movie_budget = movie.budget
      movie_poster_path = movie.poster_path
      movie_wiki_url = movie.wiki_url
      begin 
      # add movie
      new_movie = Movie.new
      new_movie.name = movie_name
      new_movie.runtime = movie_running_time
      new_movie.language = movie_language
      new_movie.release_date_s = movie_release_date_s
      new_movie.release_date = movie_release_date
      new_movie.estimated_budget = movie_budget
      new_movie.wiki_link = "http://en.wikipedia.org#{movie_wiki_url}"
      new_movie.save
      # add poster

      unless movie_poster_path.blank?
        @poster = Poster.new(:poster_remote_url => movie_poster_path, :name => movie_name, :rank => 1)
        @poster.save
        tagname = Tag.where("lower(name) = ?", movie_name.downcase)
        if tagname.blank?
          @tag = Tag.new(:name => movie_name)
          @tag.save
          @tag_id = @tag.id
        else
          @tag_id = tagname[0].id
        end
        @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => new_movie.id,:tagger_type => 'Movie', :context =>'tags')
        @tagging.save
        @tagging = Tagging.new(:tag_id => 331, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => 'poster', :context =>'tags')
        @tagging.save
      end
      # add cast
      TamilMovieStar.add_cast(movie.id,new_movie.id)
      puts "#{ctr} | #{movie.id} | #{movie.name} | #{movie.release_date} | #{movie.release_date_s}"
      ctr += 1
      movie.import_status = true 
      movie.save
      rescue
       puts "skipped #{movie.name}"
      end     
    end
  end
end
