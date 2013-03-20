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

def getRelatedLinks(searchString, url)
	doc = Nokogiri::HTML(open(url))
	relatedLinks = doc.css('.msrl a')

	if relatedLinks.length < 5
		relatedLinks = doc.css('p a')
	end

	i = $resultsObj[searchString]["relatedLinks"].length + 1
	relatedLinks.each do |link|
		$resultsObj[searchString]["relatedLinks"][i] = link.text
		i += 1
	end
end

def getAds(doc)
	ads = [
		doc.css('#pa1')[0],
		doc.css('#pa2')[0],
		doc.css('#pa3')[0]
	]
	p 'Ads'
	p doc.css('.ac')[0]
	p doc.css('.taf')[0]
	if ads.length > 0
		for ad in ads
			if ad != nil then getAd(ad) end
		end
	end

end

def getAd(ad)
	i = 0
	p ad#[0]['href'].gsub(/^.+http\:\/\//,'')
	wrapper = ad[0]
	until i > 4 or wrapper.name == 'li'
		wrapper = wrapper.parent
	end
	if wrapper.name == 'li'
		#p wrapper.children[0]
		if wrapper.css('.ac').length > 0
			p wrapper.css('.ac').text
		elsif wrapper.children[4].name == 'span'
			p wrapper.children[4].text
		end
	end		
end

$resultsObj = {}

if ARGV[0][0] == '-'
	$args = ARGV[1..ARGV.length]
	$mode = ARGV[0][1..ARGV[0].length]
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

if $mode == "searchOnly"
	$resultsObj.each do |k, v|
		p k
		p "TERMS:"
		v["searchResults"].each do |rank, result|
			p result["title"]
		end
		p "URLs:"
		v["searchResults"].each do |rank, result|
			p result["url"]
		end
		p ""
	end
else
	p $resultsObj
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