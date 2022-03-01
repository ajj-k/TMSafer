require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require './models'
require 'sinatra-websocket'

enable :sessions

get '/' do
    erb :index
end