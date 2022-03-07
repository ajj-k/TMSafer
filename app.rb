require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require './models'
require 'google_drive'

enable :sessions

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

# config.jsonを読み込んでセッションを確立
# この部分はテストを兼ねている
session_google = GoogleDrive::Session.from_config("config.json")
#sp = session_google.spreadsheet_by_url("https://docs.google.com/spreadsheets/d/1PdDmQSXqN_FnRhGj9mAhyhZDTdt1r2OrgJL-N4Y2ZMI/edit#gid=1393875168")
#ws = sp.worksheet_by_title("TMS")

get '/' do
    #ws[2, 1] = "foo" # セルA2
    #ws[2, 2] = "bar" # セルB2
    #ws.save
    erb :sign_in
end

get '/sign_up' do
   erb :sign_up 
end

post '/sign_in' do
    user = User.find_by(mail: params[:mail])
    if user && user.authenticate(params[:password])
       session[:user] = user.id 
    end
    redirect '/home'
end

post '/sign_up' do
    @user = User.create(mail: params[:mail], password: params[:password],
    password_confirmation: params[:password_confirmation]) 
    if @user.persisted? #登録済みだった場合の確認
        session[:user] = @user.id 
    end
    redirect '/home' 
end

get '/home' do
   erb :home 
end

post '/logout' do
    session[:user] = nil
    session[:memory] = nil
    redirect '/'
end

post '/check' do
    @error_check = !@error_check
    begin
    session[:memory] = nil
    @tms = params[:tms]
    ws_memory = ""
    sp_check = session_google.spreadsheet_by_url(@tms)
    ws_check = sp_check.worksheet_by_title("TMS")
    roop = true
    session[:memory] = []
    i = 21
    while roop do
        if ws_check[i,4].length != 0
            (0..10).each do |t|
                #puts 6+t
                #puts ws_check[i,6+t]
                if ws_check[i,6+t].length != 0
                    ws_memory = ws_check[i,6+t]
                    puts "get"
                end
                #puts ws_memory
            end
            #puts ws_check[i,4]
            #puts ws_check[i,5]
            #puts ws_memory
            #puts "---------"
            session[:memory].push([ws_check[i,4], ws_check[i,5], ws_memory])
            ws_memory = ""
        else
            roop = false
            break
        end
        i += 1
    end
    #puts session[:memory]
    rescue
        puts 'error'
        @error_check = true
    end
    redirect "/home"
end