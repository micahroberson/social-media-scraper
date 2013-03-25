require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'digest/sha1'
require 'restclient'


$scrapeInterval = 15*60
$scrapeRetries = 3
$products = {}
$searchResults = {}
$referenceSite = "michaelKors"
$googleSERPLimit = 3
$googleShoppingLimit = 1
$sitesToSkip = /(wordpress|newbigfacewatches|blogspot|appspot|discountshop|facebook|tumblr)/

# p "How many items to pull?"
# $productLimit = gets.chomp().to_i
$productLimit = 5
# p "Limit to a site? (type site name or if not just press enter)"
# $filter = gets.chomp()
#$filter = 'macys'

$siteConfig = {
  "michaelKors" =>
    {
      'baseUrl' => 'http://www.michaelkors.com',
      'productsPage' => '/store/catalog/templates/P6.jhtml?itemId=cat7501&parentId=cat4801&masterId=cat000000&cmCat=&page=&view=all&filter1Type=&filter1Value=&filter2Type=&filter2Value=&filterOverride=&sort=&navid=viewall&viewClick=true',
      'productSelector' => '.productlink'
    }
}

def getPriceString(site, doc, link = '')
  if site == "michaelKors"
    doc.css('.Black10V').each do |el|
      if el.text.match(/\$[0-9]+/) ; return el.text ; end
    end
  elsif site == "amazon.com"
    return doc.css('.priceLarge').text
  elsif site == "zappos.com"
    return doc.css('span.price').text
  elsif site == "watchessalecenter.com"
    return 'redirect to Amazon'
  elsif site == "worldofwatches.com"
    #return doc.css('td font[color="red"]').text
    #Need to look at AJAX
    a = doc.css('td .details').find {|i| i.text.match(/your\sprice:/i)}
    return a.parent.css('td[align=left]').text
  elsif site == "houseoffraser.co.uk"
    return doc.css('.price').text + ' (GBP)'
  elsif site == "www1.macys.com"
    #return doc.css('.prices>span').text
    return doc.css('meta[itemprop="price"]')[0]["content"]
    #doc.css('meta').find {|i| i['itemprop'] == 'price'}
    #p doc.css('meta[itemprop="price"]')[0]
    #<meta itemprop="price" content="$275.00" />
  elsif site == "watchshop.com"
    return doc.css('.newprice').text + ' (GBP)'
  elsif site == "girardinjewelers.com"
    return 'price not listed'
  elsif site == "dexclusive.com"
    return doc.css('.special-price .price').text
  end
  return nil
rescue
  return nil
end

def parseHref(urlRoot, href)
  if ["amazon.com", "zappos.com"].include? urlRoot
    return href.match(/^([^\&]+)/)[1]
  end
    
  return href.match(/^(.+)\&sa=/)[1]
end

def getProductId(site, doc, link='')
  if site == "michaelKors"
    return link.match(/prod([0-9]+)/)[1] || 'prod' + $products.length
  end
  return nil
end

def getProductName(site, doc, link='')
  if site == "michaelKors"
    return doc.css('h1').text
  end
  return nil
end

def getSKU(site, doc, link='')
  if site == "michaelKors"
    return doc.css('.vendor_style')[0].text.match(/MK[0-9]+/)[0] || doc.css('.vendor_style')[0].text
  end
  return nil
end

def getStockStatus(site, doc, link = '')
  if site == "michaelKors"
    return doc.css('img[name=prod' + getProductId(site, doc, link) + 'Status]')[0]['src']
  elsif site == 'amazon.com'
    return doc.css('.buying>span').text
  elsif site == "houseoffraser.co.uk"
    return doc.css('.stockMessage').text
  elsif site == "www1.macys.com"
    a = doc.css('script').find {|i| i.text.match('isAvailable')}
    return a.text.match(/isavailable[^,]+/i)[0]
  elsif site == "zappos.com"
    return doc.css('#oosLimitedTag').text
  end
  return nil
rescue 
  return nil
end

def parsePriceString(priceString)
  begin
    return priceString.gsub(',','').match(/[0-9\.]+/)[0].to_f
  rescue
    return nil
  end
end

def getProductList(site)
  opts = $siteConfig[site]
  url = opts["baseUrl"] + opts["productsPage"]
  doc = Nokogiri::HTML(open(url))
  productLinks = doc.css(opts['productSelector'])
  i = 0
  productLinks.each do |productLink|
    break if i >= $productLimit
    i+=1
    link = opts["baseUrl"] + productLink['href']

    #Follow link
    doc = Nokogiri::HTML(open(link))

    #get product id
    productId = getProductId(site, doc, link)
    
    #initialize hash
    $products[productId] = {
      :link => link,
      :product_id => productId
    }

    $products[productId][:name] = getProductName(site, doc, link)
    $products[productId][:priceString] = priceString = getPriceString(site, doc, link)
    $products[productId][:price] = price = priceString ? parsePriceString(priceString) : nil
    $products[productId][:sku] = getSKU(site, doc, link)
    stockStatus = $products[productId][:stock_status] = getStockStatus(site, doc, link)
    if !price || !stockStatus
      $products[productId][:html_dump] = doc.serialize()
    end
  end
end

class PriceScraperObject
  def self.attr_accessor(*vars)
    @attributes ||= []
    @attributes.concat vars
    super(*vars)
  end
  def self.attributes
    @attributes
  end
  #Following block needed so that the subclass can get attrs
  def attributes
    self.class.attributes
  end
end

class SearchResult < PriceScraperObject 
  attr_accessor :href, :title, :citation, :urlRoot, :previewText, :priceString, :price, :stockStatus
  def initialize(result)
    link = result.css('h3.r a')
    @href = CGI::unescape(link[0]['href'].gsub('/url?q=', ''))

    @citation = result.css('cite').text
    @title = link.text
    @urlRoot = @citation.gsub('www.', '').match(/([^\/]+)\//)[1] || @citation.gsub('www.', '')
    @previewText = result.css('span.st').text
    @priceString = result.css('.f.slp').text
  end
end

def getGoogleSearchResults(sku)
  i = -1
  $googleSERPLimit.times do
    i += 1
    doc = Nokogiri::HTML(open("http://www.google.com/search?q=" + sku + "&start=" + (10 * i).to_s))
    results = doc.css('li.g')
    results.each do |result|
      href = result.css('h3.r a')[0]['href']

      #skip if this is a google result (e.g., images, shopping)
      next if !href.match(/^\/url\?q/) || href.match($sitesToSkip) || ($filter && !href.match($filter))

      id = Digest::SHA1.hexdigest(href)
      $searchResults[id] = SearchResult.new(result)
    end
  end
end

def getGoogleShoppingResults(sku)
  i = -1
  $googleShoppingLimit.times do
    i += 1
    doc = Nokogiri::HTML(open("http://www.google.com/search?q=" + sku + "&tbm=shop&start=" + (10 * i).to_s))
    results = doc.css('.pslimain')
    results.each do |result|
      href = result.css('h3.r a')[0]['href']

      #skip if this is a google result (e.g., images, shopping)
      next if !href.match(/^\/url\?q/) || href.match($sitesToSkip) || ($filter && !href.match($filter))

      id = Digest::SHA1.hexdigest(href)
      $searchResults[id] = SearchResult.new(result)
    end
  end
end 

def getPrices
  $searchResults.each do |key,data|
    begin
      url = parseHref(data.urlRoot, data.href)
      doc = Nokogiri::HTML(open(url))
    rescue
      url = data.href.match(/^([^\&]+)/)[1]
      begin
        doc = Nokogiri::HTML(open(url))
      rescue
        next
      end
    end
    data.priceString = getPriceString(data.urlRoot, doc) || data.priceString
    data.price = parsePriceString(data.priceString)
    data.stockStatus = getStockStatus(data.urlRoot, doc) 
  end
end


getProductList($referenceSite)

$siteCount = {}

$products.each do |key, product|
  p product[:name]
  p product[:price]
  p product[:sku]
  getGoogleSearchResults(product[:sku])
  getPrices
  $searchResults.each do |key,data|
    p data.urlRoot + ': '+ (data.stockStatus || 'no stock status') + ' (' + (data.priceString || 'no price string') + ')'
    if $siteCount[data.urlRoot]
      $siteCount[data.urlRoot] = $siteCount[data.urlRoot] + 1
    else
      $siteCount[data.urlRoot] = 1
    end
  end
end
$siteCount.each do |k, v|
  p k + ': ' + v.to_s
end