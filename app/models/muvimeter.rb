class Muvimeter < ActiveRecord::Base
require 'arel'
require 'open-uri'
require 'nokogiri'

  def self.fetch_movie_name(pub_id, pub_url)
    if pub_id == 10101 and pub_url =~ /namastey_london.html/
       pub_url = "http://www.whatsonindia.com/WhatsOnTV/Program/Namastey_London.aspx"
 
    elsif pub_id == 10101 and pub_url =~ /bodyguard.html/
      pub_url = "http://www.whatsonindia.com/WhatsOnTV/Program/Bodyguard.aspx"        

    elsif pub_id == 10101 and pub_url =~ /singham.html/
      pub_url = "http://www.whatsonindia.com/WhatsOnTV/Program/Singham.html"
    end

    doc = Nokogiri::HTML(open(pub_url))
    muvi_name = doc.xpath("//div[@id='ctl00_MainContent_mainProgInnerTitle']/a[1]").text

    return muvi_name
     
  end
end
