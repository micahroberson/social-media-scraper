#config.ru
# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'rack'

require './app.rb'
set :root, Pathname(__FILE__).dirname
set :environment, :production
set :run, false
run Sinatra::Application