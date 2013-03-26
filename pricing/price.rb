require 'mongo'
require 'mongoid'
require './search_result'

ENV['MONGOID_ENV'] = 'development'

Mongoid.load!('mongoid.yml')

class Price
  include Mongoid::Document

  field :created_at, :type => DateTime, :default => Time.now

  field :price_string, :type => String
  field :price, :type => Float
  field :stock_status, :type => String

  belongs_to :search_result

end