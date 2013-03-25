require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'digest/sha1'
require 'restclient'

REQUEST_URL = "http://www1.macys.com/shop/product/michael-kors-watch-mens-chronograph-runway-black-and-gold-tone-stainless-steel-bracelet-45mm-mk8265?ID=711745"

# name_term = 'dan'

# if page = RestClient.post(REQUEST_URL, {'name'=>name_term, 'submit'=>'Get+Listing'})
#   puts "Success finding search term: #{name_term}"
#   File.open("data-hold/fecimg-#{name_term}.html", 'w'){|f| f.write page.body}
  
#   npage = Nokogiri::HTML(page)
#   rows = npage.css('table tr')
#   puts "#{rows.length} rows"
  
#   rows.each do |row|
#     puts row.css('td').map{|td| td.text}.join(', ')
#   end
  
# end  


doc = Nokogiri::HTML(open(REQUEST_URL))
#p doc.css('meta')

#p doc.css('meta[itemprop="price"]')
a =  doc.css('meta').find {|i| i['itemprop'] == 'price'}
