require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

# Open the initial page to grab the cookie from it
p1 = open('https://web.apps.markit.com/WMXAXLP?YYY2220_zJkhPN/sWPxwhzYw8K4DcqW07HfIQykbYMaXf8fTzWT6WKnuivTcM0W584u1QRwj')

# Save the cookie
cookie = p1.meta['set-cookie'].split('; ',2)[0]

# Open the JSON data page using our cookie we just obtained
p2 = open('https://web.apps.markit.com/AppsApi/GetIndexData?indexOrBond=bond&ClientCode=WSJ',
          'Cookie' => cookie)

# Get the raw JSON
json = p2.read

# Parse it
data = JSON.parse(json)

# Feed the html portion to Nokogiri
doc = Nokogiri.parse(data['html'])

# Extract the values
values = doc.css('td.col2 span')
puts values.map(&:text).inspect

=> ["0.02%", "0.02%", "n.a.", "-0.03%", "0.02%", "0.04%", 
    "0.01%", "0.02%", "0.08%", "-0.01%", "0.03%", "0.01%", "0.05%", "0.04%"]