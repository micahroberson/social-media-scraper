@scrapeRetries = 3
$pages = [1, 2, 0, 4]

def abc
	p "start test"
	for i in [3, 2, 0, 4]
		begin
			divide(i)
		rescue 
			p "error, retrying"
			divide(i + 1)
		end
	end
end

def divide(num)
	p 10 / num
end

abc

for num in $pages
  retries = 0
  begin
    p "Scraping " + num
    divide(num)
  rescue
    until retries >= @scrapeRetries
      begin
        p "Error, quitting driver"
        begin
          p 'driver.quit'
          #@driver.quit
        rescue
          "couldn't quit driver"
        end
        p "relaunching driver"
        # @driver = Selenium::WebDriver.for :firefox
        # login
        p "Scraping " + num.to_s
        abc(num)
        break
      rescue
        p "error with scrape, " + retries.to_s + " retries"
        retries+=1
      end
    end
  end
end