require 'bundler'
Bundler.require

require './app'
run Sinatra::Application

config.time_zone = 'Tokyo'