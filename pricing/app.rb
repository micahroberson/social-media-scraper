require "bundler/setup"
require 'sinatra'
require "sinatra/reloader" if development?
require 'json'
require './product'
require './search_result'
require './price'

# set :server, 'thin'

# use Rack::CommonLogger

# log = File.new("logs/sinatra.log", "a+")
# log.sync = true
# STDOUT.reopen(log)
# STDERR.reopen(log)

get '/products' do
  content_type :json
  Product.all.to_json
end

get '/search_results' do
  content_type :json
  SearchResult.all.to_json
end

get '/prices' do
  content_type :json
  Price.all.to_json
end