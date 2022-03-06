require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require './models'
require 'google_drive'

enable :sessions
# config.jsonを読み込んでセッションを確立
session = GoogleDrive::Session.from_config("config.json")
  
sp = session.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1PdDmQSXqN_FnRhGj9mAhyhZDTdt1r2OrgJL-N4Y2ZMI/edit#gid=1393875168")
    
ws = sp.worksheet_by_title("TMS")

get '/' do
    ws[2, 1] = "foo" # セルA2
    ws[2, 2] = "bar" # セルB2
    ws.save
    erb :index
end