require 'mongo'
require 'mongoid'
require './price'

ENV['MONGOID_ENV'] = 'development'

Mongoid.load!('mongoid.yml')

class SearchResult
  include Mongoid::Document

  field :created_at, :type => DateTime, :default => Time.now
  field :updated_at, :type => DateTime, :default => Time.now

  field :sku, :type => String
  field :site_name, :type => String
  field :href, :type => String
  field :title, :type => String
  field :citation, :type => String
  field :url_root, :type => String
  field :preview_text, :type => String
  field :price_string, :type => String
  field :results_index, :type => Integer

  has_many :prices

  # def self.current_search_results
  #   map = %Q{
  #     function() {
  #       emit("#{this.site_name}:#{this.sku}:#{this.url_root}", {site_name: this.site_name})
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