require 'nokogiri'
require 'open-uri'
require 'json'
require 'csv'
require 'cgi'


def getResults(searchString, url)
	doc = Nokogiri::HTML(open(url))
	results = doc.css('h3.r a')
	i = $resultsObj[searchString]["searchResults"].length + 1
	results.each do |result|
		$resultsObj[searchString]["searchResults"][i] = {
			"title" => result.text,
			"url" => result['href'].gsub(/^\/url\?q=/, "").gsub(/\&sa.+/, "")
		}
		i += 1
	end
end

def getShoppingResults(searchString, url)
	doc = Nokogiri::HTML(open(url))
	results = doc.css('li.g')
	i = $resultsObj[searchString]["shoppingResults"].length + 1
	results.each do |result|
		$resultsObj[searchString]["shoppingResults"][i] = {
			"text" => result.css('.pslimain .r').text,
			"description" => result.css('.pslimain').text,
			"url" => result.css('h3.r a')[0]['href'].gsub(/^.+http\:\/\//,''),
			"img" => result.css('.psliimg img')[0]['src'],
			"priceBlock" => result.css('.psliprice').text,
			"priceBase" => result.css('.psliprice').children[0].text,
			"reseller" => result.css('.psliprice').children[1].text
		}
		i += 1
		if result.css('.psliprice').children[1].text.match(/^from/) != nil
			itemId = result.css('h3.r a')[0]['href'].match(/product\/([0-9]+)/)
			if itemId != nil
				itemId = itemId[1]
			else
				itemId = result.css('h3.r a')[0]['href'].match(/cid\=([0-9]+)/)
				if itemId != nil
					itemId = itemId[1]
				end
			end

			if itemId != nil
				subUrl = "http://www.google.com/shopping/product/" + itemId
				subDoc = Nokogiri::HTML(open(subUrl))
				subDoc.css('.online-sellers-row').each do |subResult|
					$resultsObj[searchString]["shoppingResults"][i] = {
						"text" => result.css('.pslimain').text,
						"description" => result.css('.pslimain').text,
						"reseller" => subResult.css('.seller-name').text,
						"url" => subResult.css('a')[0]['href'].gsub(/^.+http\:\/\//,''),
						"resellerRating" => 
							if subResult.css('.rating-col .ps-sprite')[0] != nil
								subResult.css('.rating-col .ps-sprite')[0]["title"] 
							else 
								nil 
							end,
						"resellerRatings" => 
							if subResult.css('.rating-col a').text.gsub(",", "").match(/[0-9]+/) != nil
								subResult.css('.rating-col a').text.gsub(",", "").match(/[0-9]+/)[0]
							else
								nil
							end,
						"offers" => subResult.css('td')[2].text,
						"priceBase" => subResult.css('.base_price').text,
						"taxShipping" => subResult.css('.taxship-col').text,
						"priceTotal" => subResult.css('.total-col').text,
					}
					#p $resultsObj[searchString]["shoppingResults"][i]
				end

				i += 1
			end
		end
		
	end
end

$resultsObj = {}

if ARGV[0][0] == '-'
	$args = ARGV[1..ARGV.length]
	$mode = ARGV[0][1..ARGV[0].length]
else
	$mode = ''
	$args = ARGV
end

if $mode != "gilt"
	for term in $args
		searchString = CGI.escape(term)
		$resultsObj[searchString] = {
			"searchResults" => {},
			"shoppingResults" => {},
			"relatedLinks" => {}
		}
		
		url = "http://www.google.com/search?q=" + searchString
		urlShopping = url + '&tbm=shop'

		getResults(searchString, url)
		getResults(searchString, url + "&start=10")

		if $mode != "searchOnly"
			getRelatedLinks(searchString, url)
			getShoppingResults(searchString, urlShopping)
			getShoppingResults(searchString, urlShopping + "&start=10")
		end
	end
end



# $resultsObj.each do |k, v|
# 	v.each do |k, v|
# 		v.each do |k, v|
# 			v.each do |k, v|
# 				p k + ': ' + v
# 			end
# 		end
# 	end
# end
# $resultsObj.each do |result|
# 	p result.keys
# 	# result.each do |el|
# 	# 	p el.keys
# 	# end
# end

# http://www.google.com/search?q=mast+brothers+chocolate