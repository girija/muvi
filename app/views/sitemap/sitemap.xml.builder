xml.instruct! :xml, :version=>"1.0" 
 
xml.urlset('xmlns:xsi'.to_sym => "http://www.w3.org/2001/XMLSchema-instance",
'xsi:schemaLocation'.to_sym => "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd",
         'xmlns'.to_sym => "http://www.sitemaps.org/schemas/sitemap/0.9"
  ) do
 
  @pages.each do |page|
    xml.url do
      xml.loc page_url(:only_path => false, :name => page.link)
      xml.lastmod page.updated_at.strftime("%Y-%m-%d")
      xml.changefreq 'monthly'
      xml.priority '0.5'
    end
  end
end
