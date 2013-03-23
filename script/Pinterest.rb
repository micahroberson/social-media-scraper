require 'selenium-webdriver'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'

@driver = Selenium::WebDriver.for :firefox
@base_url = "http://pinterest.com/"
@results = []
@arguments = ['gilt', 'armani', 'michaelkors']
	

def goToSite(pinners)
	pinners.each do |pinner|
		#go to the pinner sites that we want to collect intel from
		url = "#{@base_url}#{pinner}/pins/" 
		@driver.get(url)
		
		#wait for page to load
		sleep(2)
		$totalData = []	
		scrapePage(url)

	end
end
		
def scrapePage(address)
	@driver.get(address)
	doc = Nokogiri::HTML(@driver.page_source)
	title = doc.css('.ProfileInfo .content h1').text.strip
	summaryData = doc.css('#ContextBar .links li a strong')
	summaryData.each do |data|
		dataataString = data.text
		dataInteger = dataString.gsub(",", '').to_i
		$totalData << dataInteger
	end

	

	followersInfo = doc.css('#ContextBar .follow li a strong')
	followersInfoInt = followersInfo[0].text.gsub(",",'').to_i
	@pins = doc.css('.pin')
	page = [title, [followersInfoInt, $totalData]]
	

	#$resultsObj[address] = {}

	@pins.each do |pin|
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
		page << [description, likesCount, repinsCount, where]
		
	end
	@results << page
end




goToSite(@arguments)
print @results




