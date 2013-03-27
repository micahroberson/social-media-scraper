require './config'
require './scraper_methods'
require './product'
require './search_result'
require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'digest/sha1'
require 'restclient'

# Updates products in the database from manufacturers website (ie. the products to search for later)
def updateProductList

  puts "Start - Check Reference Sites for New Products and/or Price Changes"
  puts "Checking #{SITE_CONFIG.size} sites for #{PRODUCT_LIMIT} products each"

  # Loop through sites to check products for
  SITE_CONFIG.each do |site, opts|

    puts "Processing Site: #{site.humanize.capitalize}"

    currentProducts = {}
    url = opts["baseUrl"] + opts["productsPage"]
    doc = Nokogiri::HTML(open(url))
    productLinks = doc.css(opts['productSelector'])

    productLinks.each_with_index do |productLink, i|

      break if i >= PRODUCT_LIMIT

      puts "Processing Product Link: #{i}"

      link = opts["baseUrl"] + productLink['href']

      #Follow link
      doc = Nokogiri::HTML(open(link))

      #get product id
      productId = getProductId(site, doc, link, i)
      
      #initialize hash
      currentProducts[productId] = {
        link: link,
        product_id: productId,
        site_name: site
      }

      currentProducts[productId][:name] = getProductName(site, doc, link)
      currentProducts[productId][:priceString] = priceString = getPriceString(site, doc, link)
      currentProducts[productId][:price] = price = priceString ? parsePriceString(priceString) : nil
      currentProducts[productId][:sku] = getSKU(site, doc, link)
      stockStatus = currentProducts[productId][:stock_status] = getStockStatus(site, doc, link, i)

      if !price || !stockStatus
        currentProducts[productId][:html_dump] = doc.serialize()
      end

      puts "Find or Create Product: #{productId} at $#{price}"

      Product.where(currentProducts[productId]).first_or_create

    end

    puts "Current #{site.humanize.capitalize} Product Count: #{Product.count}"

  end

end

# Updates the search results stored in the db which are used to gather pricing data at more frequency intervals
def updateGoogleSearchResults

  puts "Updating Google Search Results"

  SITE_CONFIG.each do |site, opts|

    Product.where(site_name: site).distinct(:sku).each do |sku|

      puts "Grabbing Results for #{site.humanize.capitalize}:#{sku}"

      getGoogleSearchResults(sku, site)

    end

  end

end

def updateGoogleShoppingResults

  puts "Updating Google Shopping Results"

  SITE_CONFIG.each do |site, opts|

    Product.where(site_name: site).distinct(:sku).each do |sku|

      puts "Grabbing Google Shopping Results for #{site.humanize.capitalize}:#{sku}"

      getGoogleShoppingResults(sku, site)

    end

  end

end

# Updates pricing data in the db based on the search results already stored in the db
def updatePrices

  puts "Updating Search Result Prices"

  SITE_CONFIG.each do |site, opts|

    SearchResult.order_by([[:updated_at, :desc]]).where(site_name: site).limit(GOOGLE_SERP_LIMIT * 10).each do |searchResult|

      puts "Grabbing Prices for #{site.humanize.capitalize}:#{searchResult.sku}"

      getPrices(searchResult)

    end

  end

end

# updateProductList
# updateGoogleSearchResults
updateGoogleShoppingResults
# updatePrices
