require 'open-uri'
require 'json'
require 'cgi'
require 'nokogiri'
require 'digest/sha1'
require 'restclient'
require './config'
require './search_result'

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
  puts "No Selector available for: #{site}"
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

def getProductId(site, doc, link, index)
  if site == "michaelKors"
    return link.match(/prod([0-9]+)/)[1] || 'prod' + index
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

def getStockStatus(site, doc, link, index)
  if site == "michaelKors"
    return doc.css('img[name=prod' + getProductId(site, doc, link, index) + 'Status]')[0]['src']
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

def getGoogleSearchResults(sku, site)

  puts "Updating/Creating Search Results for #{sku}"

  i = -1
  GOOGLE_SERP_LIMIT.times do

    i += 1
    doc = Nokogiri::HTML(open("http://www.google.com/search?q=" + sku + "&start=" + (10 * i).to_s))
    results = doc.css('li.g')
    results.each_with_index do |result, index|

      href = result.css('h3.r a')[0]['href']

      #skip if this is a google result (e.g., images, shopping)
      next if !href.match(/^\/url\?q/) || href.match(SITES_TO_SKIP) || ($filter && !href.match($filter))

      attrs = {}
      link = result.css('h3.r a')
      attrs[:href] = CGI::unescape(link[0]['href'].gsub('/url?q=', ''))
      attrs[:citation] = result.css('cite').text
      attrs[:title] = link.text
      attrs[:url_root] = attrs[:citation].gsub('www.', '').match(/([^\/]+)\//)[1] || attrs[:citation].gsub('www.', '')
      attrs[:preview_text] = result.css('span.st').text
      attrs[:price_string] = result.css('.f.slp').text
      attrs[:results_index] = (10 * i) + index
      attrs[:site_name] = site
      attrs[:sku] = sku

      sr = SearchResult.where(site_name: site, sku: sku, url_root: attrs[:url_root]).first_or_create
      sr.update_attributes(attrs.merge(updated_at: Time.now))

    end

  end

  puts "#{SearchResult.where(site_name: site).count} results for #{site}"

end

def getGoogleShoppingResults(sku, site)

  i = -1
  GOOGLE_SHOPPING_LIMIT.times do

    i += 1
    url = "http://www.google.com/search?q=" + sku + "&tbm=shop&start=" + (10 * i).to_s + "&tbs=vw:l"
    
    doc = Nokogiri::HTML(open(url))
    productLink = doc.css('#ires ol > li h3.r a')[0]
    link = "http://www.google.com#{productLink['href']}"
    #Follow link
    puts "Url to be opened: #{link}"
    doc = Nokogiri::HTML(open(link))

    results = doc.css('.os-main-table tr')

    results.each_with_index do |result, i|

      next if i == 0

      link = result.css('.os-seller-name a')[0]
      href = link['href']
      puts "href: #{href}"
      #skip if this is a google result (e.g., images, shopping)
      next if !href.match(/^\/url\?q/) || href.match(SITES_TO_SKIP) || ($filter && !href.match($filter))

      attrs = {}
      attrs[:href] = CGI::unescape(href.gsub('/url?q=', ''))
      # attrs[:citation] = result.css('cite').text
      attrs[:title] = link.text
      attrs[:url_root] = attrs[:href].gsub('www.', '').match(/([^\/]+)\//)[1] || attrs[:href].gsub('www.', '')
      # attrs[:preview_text] = result.css('span.st').text
      attrs[:price_string] = result.css('.os-base_price').text
      attrs[:price] = parsePriceString attrs[:price_string]
      attrs[:results_index] = (10 * i) + index
      attrs[:site_name] = site
      attrs[:sku] = sku
      attrs[:shopping] = true

      sr = SearchResult.where(site_name: site, sku: sku, url_root: attrs[:url_root]).first_or_create
      sr.update_attributes(attrs.merge(updated_at: Time.now))
      puts sr.inspect

    end

  end

end 

def getPrices(searchResult)

    begin
      url = parseHref(searchResult.url_root, searchResult.href)
      doc = Nokogiri::HTML(open(url))
    rescue
      url = searchResult.href.match(/^([^\&]+)/)[1]
      begin
        doc = Nokogiri::HTML(open(url))
      rescue
        puts "Failed to open URL: #{url}"
        return
      end
    end
    attrs = {}
    attrs[:price_string] = getPriceString(searchResult.url_root, doc) || searchResult.price_string
    attrs[:price] = parsePriceString(searchResult.price_string)
    attrs[:stock_status] = getStockStatus(searchResult.url_root, doc, '', 0)

    searchResult.prices.where(attrs).first_or_create
    puts "Updating Price info for #{searchResult.sku}"
end

