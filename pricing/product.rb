require 'mongo'
require 'mongoid'

ENV['MONGOID_ENV'] = 'development'

Mongoid.load!('mongoid.yml')

class Product
  include Mongoid::Document

  field :created_at, :type => DateTime, :default => Time.now
  field :updated_at, :type => DateTime, :default => Time.now

  field :site_name, :type => String
  field :product_id, :type => String
  field :link, :type => String
  field :name, :type => String
  field :price_string, :type => String
  field :price, :type => Float
  field :sku, :type => String
  field :stock_status, :type => String
  field :html_dump, :type => String

  # def self.unique_product_skus
  #   map = %Q{
  #     function() {
  #       emit(this.sku, {site_name: this.site_name})
  #     }
  #   }

  #   reduce = %Q{
  #     function(key, values) {
  #       return values.first.site_name;
  #     }
  #   }

  #   self.where(:created_at.gt => Date.today, status: "played").
  #     map_reduce(map, reduce).out(inline: true)
  # end

end