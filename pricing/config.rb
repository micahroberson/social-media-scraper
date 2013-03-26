SITE_CONFIG = {
  "michaelKors" =>
    {
      'baseUrl' => 'http://www.michaelkors.com',
      'productsPage' => '/store/catalog/templates/P6.jhtml?itemId=cat7501&parentId=cat4801&masterId=cat000000&cmCat=&page=&view=all&filter1Type=&filter1Value=&filter2Type=&filter2Value=&filterOverride=&sort=&navid=viewall&viewClick=true',
      'productSelector' => '.productlink'
    }
}

SCRAPE_INTERVAL = 15*60
SCRAPE_RETRIES = 3
REFERENCE_SITE = "michaelKors"
GOOGLE_SERP_LIMIT = 3
GOOGLE_SHOPPING_LIMIT = 1
SITES_TO_SKIP = /(wordpress|newbigfacewatches|blogspot|appspot|discountshop|facebook|tumblr)/
PRODUCT_LIMIT = 5