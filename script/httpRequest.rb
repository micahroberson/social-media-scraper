require 'rubygems'
require 'restclient'
require 'nokogiri'

REQUEST_URL = "http://query.nictusa.com/cgi-bin/fecimg"

name_term = 'dan'

if page = RestClient.post(REQUEST_URL, {'name'=>name_term, 'submit'=>'Get+Listing'})
  puts "Success finding search term: #{name_term}"
  File.open("data-hold/fecimg-#{name_term}.html", 'w'){|f| f.write page.body}
  
  npage = Nokogiri::HTML(page)
  rows = npage.css('table tr')
  puts "#{rows.length} rows"
  
  rows.each do |row|
    puts row.css('td').map{|td| td.text}.join(', ')
  end
  
end  