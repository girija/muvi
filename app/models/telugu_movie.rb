class TeluguMovie < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'
  set_table_name 'telugu_movie_data'

  def self.import_telugu_movie
    allmovies = TeluguMovie.find(:all, :conditions => ["import_status = false"], :order => ["id asc"])
    ctr = 1
    allmovies.each do |movie|
      movie_name = movie.name.strip
      unless movie.release_date_s.blank?
        movie_release_date_s = movie.release_date_s[0..99]
      else
        movie_release_date_s=''
      end
      unless movie.release_date.blank?
        movie_release_date = movie.release_date
      else
        movie_release_date = ''
      end
      movie_language = 'Telugu'
      unless movie.box_office.blank?
        movie_box_office = movie.box_office
      else
        movie_box_office = ''
      end
      unless movie.running_time.blank?
        movie_running_time = movie.running_time
      else
        movie_running_time=''
      end
      unless movie.budget.blank?
        movie_budget = movie.budget
      else
        movie_budget = ''
      end
      unless movie.poster_path.blank?
        movie_poster_path = movie.poster_path
      else
        movie_poster_path = ''
      end
      unless movie.wiki_url.blank?
        movie_wiki_url = movie.wiki_url
      else
        movie_wiki_url=''
      end
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
        @tagging = Tagging.new(:tag_id => @tag_id, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_id => new_movie.id,:tagger_type => 'Movie', :context =>'tags')
        @tagging.save
        @tagging = Tagging.new(:tag_id => 331, :taggable_id => @poster.id, :taggable_type => 'Poster', :tagger_type => 'poster', :context =>'tags')
        @tagging.save
      end
      # add cast
      TeluguMovieStar.add_cast(movie.id,new_movie.id)
      puts "#{ctr} | #{movie.id} | #{movie.name} | #{movie.release_date} | #{movie.release_date_s} | #{movie_poster_path}"
      movie.import_status = true
      movie.save
      ctr += 1
    end
  end

  def self.update_movie_name
    year = 1990

    while year < 2013
    ctr = 1
    movies = Movie.where("name like '%(#{year})%'").order('id')
    movies.each do |movie|
      new_movie_name = movie.name.gsub(" (#{year})", "").strip
      puts "#{movie.name} #{new_movie_name}"
      tags = Tag.where("name = ?",new_movie_name).first
      unless tags.blank?
        puts "tag ---- #{tags.name} ---- found new"
      else
        tagso = Tag.where("name = ?", movie.name).first
        unless tagso.blank?
          tagso.name = new_movie_name
          tagso.save
        end
        movie.name = new_movie_name
        movie.save
      end
      ctr += 1
    end
  end
  year += 1
  end
end
