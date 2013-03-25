require "selenium-webdriver"
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
#require 'highline'


$pages =  ["gilt","Etsy","fab.com","hautelook","zappos","burberry","toms","RueLaLa","ModCloth","hayneedle","shopbop","MRPORTERLIVE","narscosmetics","quirky","thinkgeek","warbyparker","31PhillipLimOfficial","ragandbonenewyork","AlexanderWangNY","gq","hm","uniqlo.us","GiltCity","Coach","Fendi","LouisVuitton","michaelkors","RalphLauren","OXO"]

@driver = Selenium::WebDriver.for :firefox
@base_url = "https://www.facebook.com/"
@accept_next_alert = true
@driver.manage.timeouts.implicit_wait = 30
@scrapeInterval = 15*60
@daysToGoBack = 7
@scrapeRetries = 3

def login
  @driver.get(@base_url)

  #Test if we need to log in
  if element_present?(:id, "pass")
    @driver.find_element(:id, "email").clear
    @driver.find_element(:id, "email").send_keys $username
    @driver.find_element(:id, "pass").clear
    @driver.find_element(:id, "pass").send_keys $password
    @driver.find_element(:css, "#loginbutton input").click
  end

  #wait for machine name box to load
  !60.times{ break if (element_present?(:css, "#machine_name") || element_present?(:css, "#checkpointSubmitButton") rescue false); sleep 1 }

  #Test if we need to name machine
  if element_present?(:id, "machine_name")
    @driver.find_element(:id, "machine_name").clear
    @driver.find_element(:id, "machine_name").send_keys "testsel"
    @driver.find_element(:css, "#checkpointSubmitButton input").click
  elsif element_present?(:id, "checkpointSubmitButton")
    #situation where they need you to verify login
    @driver.find_element(:css, "#checkpointSubmitButton input").click
    !60.times{ break if (element_present?(:css, "#checkpointSecondaryButton") rescue false); sleep 1 }
    @driver.find_element(:css, "#checkpointSecondaryButton input").click
    2.times do 
      !60.times{ break if (element_present?(:css, "#machine_name") rescue false); sleep 1 }
      @driver.find_element(:id, "machine_name").clear
      @driver.find_element(:id, "machine_name").send_keys "testsel"
      @driver.find_element(:css, "#checkpointSubmitButton input").click
    end
  end

  #Wait for homepage to load
  !60.times{ break if (element_present?(:css, "#navAccount") rescue false); sleep 1 }
end

def element_present?(how, what)
  @driver.find_element(how, what)
  true
rescue Selenium::WebDriver::Error::NoSuchElementError
  false
end

def scrollToGetMorePosts
  i = 0
  #keep scrolling to get more posts until we have enough days' worth or we exceed 10 fetches/scrolls
  while @posts.last['data-time'] && Time.at(@posts.last['data-time'].to_i) > (Date.today - @daysToGoBack).to_time && i < 11
    lastPostTime = @posts.last['data-time']
    @driver.execute_script("window.scrollTo(0,document.body.clientHeight);")
    # doc = Nokogiri::HTML(@driver.page_source)
    # @posts = doc.css('.timelineUnitContainer')

    #wait for page to load more posts
    5.times do |wait|
      sleep 2
      doc = Nokogiri::HTML(@driver.page_source)
      @posts = doc.css('.timelineUnitContainer')
      if lastPostTime != @posts.last['data-time']
        break
      end
    end

    i+=1
  end
end

def scrapePage(address)
  $resultsObj[address] = {}

  #Get likes
  @driver.get(@base_url + address + "/likes")
  #Wait for page footer to load
  !60.times{ break if (element_present?(:css, "#pageFooter") rescue false); sleep 1 }

  doc = Nokogiri::HTML(@driver.page_source)
  @likes = doc.css('.timelineLikesBigNumber')
  $resultsObj[address]['people_talking'] = @likes[0].text.gsub(',','').to_i
  $resultsObj[address]['total_likes'] = @likes[1].text.gsub(',','').to_i


  #Get posts
  @driver.get(@base_url + address + "?filter=1")

  #Wait for page footer to load
  !60.times{ break if (element_present?(:css, "#pageFooter") rescue false); sleep 1 }

  doc = Nokogiri::HTML(@driver.page_source)
  @posts = doc.css('.timelineUnitContainer')

  #Check if we need to scroll to get more posts
  scrollToGetMorePosts

  
  @posts.each do |post|
    timeId = post['data-time'].to_i
    likeSentence = post.css('.UFILikeSentence').text.gsub(',','')
    likeCount = likeSentence.match(/[0-9]+/)
    if likeCount
      likeCount = likeCount[0].to_i
    else
      likeCount = "unknown"
    end
    commentSentence = post.css('.UFIFirstCommentComponent').text.gsub(',','')
    commentCount = commentSentence.match(/[0-9]+\s*of\s*([0-9]+)/)
    if commentCount
      commentCount = commentCount[1].to_i + 2
    else
      commentCount = commentSentence.match(/([0-9]+)\s*more/)
      if commentCount
        commentCount = commentCount[1].to_i + 2
      else
        commentCount = "unknown"
      end
    end
    shares = post.css('.fbTimelineFeedbackShares').text.gsub(',','')
    if shares.to_i > 0
      shared = shares.to_i
    end

    postText = post.css('[role="article"]').text

    $resultsObj[address][timeId] = {
      :text => postText,
      :shares => shares,
      :likeSentence => likeSentence,
      :likeCount => likeCount,
      :commentSentence => commentSentence,
      :commentCount => commentCount
    }
  end

  #save screenshot
  #timestamp = Time.new.to_a
  #timestamp = timestamp[5]
  #@driver.save_screenshot "C:/Users/Kenny Chan/Documents/Dropbox/Scraper/Screenshots/" + address + ".png"
end

def parseArgs
  $username = ARGV[0]
  $password = ARGV[1]
  if $username[0..1] == '--'
    $username = $username[2..$username.length]
  else
    raise "No username provided. Please use the syntax program.rb --username --password site1 site2.."
  end
  if $password[0..1] == '--'
    $password = $password[2..$password.length]
  else
    raise "No password provided. Please use the syntax program.rb --username --password site1 site2.."
  end
  # $pages = ARGV[2..ARGV.length]
rescue 
  p "Please use the syntax program.rb --username --password site1 site2.."
end


parseArgs
login

until true == false
  $resultsObj = {}

  # require "active_support/core_ext"
  # file = File.open(Dir['../json/*'].last, "r")
  # @previousJSON = JSON.load(file)

  for address in $pages
    retries = 0
    begin
      p "Scraping " + address
      scrapePage(address)
    rescue
      until retries >= @scrapeRetries
        sleep 5
        retries+=1
        p "error with scrape, " + retries.to_s + " retries"
        begin
          p "Trying scrape " + address
          scrapePage(address)
          retries = 4
        rescue
          begin
            p "Quitting driver"
            @driver.quit
          rescue
            "couldn't quit driver"
          end
          begin
            p "relaunching driver"
            @driver = (Selenium::WebDriver.for :firefox)
            login
            p "Trying scrape " + address
            scrapePage(address)
            retries = 4
          rescue
            p "couldn't relaunch driver"
          end
        end
      end
    end
  end
  # if (defined? file) && (file.is_a? File)
  #   file.close
  # end

  timestamp = Time.new.to_s.gsub(/[\s\-\:]/, "")[0..11]
  File.open("../json/" + timestamp + ".json", "w") do |f|
    f.write($resultsObj.to_json)
  end
  p "Wrote " + timestamp
  p ""


  sleep @scrapeInterval
end


#@driver.quit