class TamilStar < ActiveRecord::Base
  require 'open-uri'
  require 'nokogiri'

  set_table_name 'tamil_star_data'


  def self.add_posters_to_stars
    ctr = 1
    celebs = Celebrity.where("date(created_at) = '2012-04-27'").order('id asc')
    celebs.each do |celeb|
      tamil_star = TamilMovieStar.where("name = ?",celeb.name).first
      if tamil_star
        if tamil_star.poster_path
          begin
            puts "#{ctr} | #{celeb.id}  | #{celeb.name} | #{tamil_star.poster_path}"
            @poster = Poster.new(:poster_remote_url => tamil_star.poster_path, :name => celeb.name, :rank => 1)
            @poster.save
            tagname = Tag.where("lower(name) = ?", celeb.name.downcase)
            if tagname.blank?
              @tag = Tag.new(:name => celeb.name)
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
            tamil_star.import_status = true
            tamil_star.save
          rescue
            puts "skipped #{tamil_star.id} | #{tamil_star.poster_path}"
          end
        end
      end
    end
  end
end
