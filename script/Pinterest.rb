require 'selenium-webdriver'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'

@driver = Selenium::WebDriver.for :firefox
@base_url = "http://pinterest.com/"
@results = {}
@arguments = ['gilt', 'michaelkors']
	

def goToSite(pinners)
	pinners.each do |pinner|
		#go to the pinner sites that we want to collect intel from
		url = "#{@base_url}#{pinner}/pins/" 
		@driver.get(url)
		
		#wait for page to load
		sleep(2)

		@driver.get(url)
		doc = Nokogiri::HTML(@driver.page_source)

		@results[Time.now] = {
			:pinner => pinner,
			:metaData => metaData(url, doc),
			:pinsData => scrapePage(url, doc)
		}
	end

	print @results
end
		
def metaData(address, doc)
	
	title = doc.css('.ProfileInfo .content h1').text.strip
	summaryData = doc.css('#ContextBar .links li a strong')
	totalPins = summaryData[1].text.gsub(",", '').to_i
	totalLikes = summaryData[2].text.gsub(",", '').to_i
	followData = doc.css('#ContextBar .follow li a strong')
	totalFollowers = followData[0].text.gsub(",", '').to_i
	totalFollowing = followData[1].text.gsub(",", '').to_i
	
	totalData = {
		:title => title,
		:totalPins => totalPins,
		:totalLikes => totalLikes,
		:followers => totalFollowers,
		:following => totalFollowing
	}

	totalData
end

def scrapePage(address, doc)	
	
	scrapeData= {}
	@pins = doc.css('.pin')
	@pins.each do |pin|
		pinId = pin['data-id']
		
		description = pin.css('.description').text
		stats = pin.css('.stats')
		likes = pin.css('.stats .LikesCount').text.gsub(",",'').strip.split(' ')
		if likes != ''
			likesCount = likes[0].to_i
		else
			likesCount = 0
		end
		
		repins = pin.css('.stats .RepinsCount').text.gsub(",",'').strip.split(' ')
		
		if repins != ''
			repinsCount = repins[0].to_i
		else
			repinsCount = 0
		end
		
		where = pin.css('.convo .NoImage a')[1].text
		
		scrapeData[pinId] = {
			:description => description,
			:likes => likesCount,
			:repins => repinsCount,
			:origin => where
		}
		
	end
	scrapeData
end

goToSite(@arguments)





