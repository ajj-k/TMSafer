require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require './models'
require 'dotenv/load'
require 'google_drive'
require 'date'
require "googleauth"

enable :sessions

credentials = Google::Auth::UserRefreshCredentials.new(
  client_id: "592312556966-ei5l1daqd3toig4gffjgdrsds350rqo5.apps.googleusercontent.com",
  client_secret: "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",
  scope: [
    "https://www.googleapis.com/auth/drive",
    "https://spreadsheets.google.com/feeds/",
  ],
  redirect_uri: "https://342c1446a83b4ebe8d2cbcdbc3ff8e9f.vfs.cloud9.ap-northeast-1.amazonaws.com/redirect"
  )

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key    = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
end

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
    
    def tms_check(url)
    session_google = GoogleDrive::Session.from_config("config.json")
    @error_check = !@error_check
    begin
    session[:memory] = nil
    ws_memory = ""
    date_check = ""
    sp_check = session_google.spreadsheet_by_url(url)
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
                    date_check = ws_check[8,6+t]
                    #puts "get"
                    #puts ws_check[8,6+t]
                end
                #puts ws_memory
            end
            #puts date_check
            #puts ws_check[i,4]
            #puts ws_check[i,5]
            #puts ws_memory
            #puts "---------"
            begin
            ws_memory_sub1, ws_memory_sub2 = tms_date_chenge(ws_memory)
            ws_memory = "#{ws_memory_sub1} / #{ws_memory_sub2}"
            rescue
                puts "tms_error"
            end
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
    end
    
    def date_chenge(date_string)
        month = date_string.slice(/^.*月/)
        day   = date_string.slice(/月.*日/)
        month.delete!("月")
        day.delete!("月")
        day.delete!("日")
        
        return "#{month.to_i}月#{day.to_i}日"
        
    end
    
    def tms_date_chenge(date_string)
        first_data = date_string.slice(/:.*~/)
        last_data  = date_string.slice(/~.*日/)
        #first_data = first_data.reverse
        #last_data  = last_data.reverse
        puts first_data
        puts last_data
        first_data.slice!(-5..-1)
        first_data.delete!(":")
        last_data.slice!(0..1)
        puts first_data
        puts last_data
        
        #return "#{first_data} / #{last_data}"
        return first_data, last_data
        
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
    @user = User.create(name: params[:name], mail: params[:mail], password: params[:password],
    password_confirmation: params[:password_confirmation]) 
    if @user.persisted? #登録済みだった場合の確認
        session[:user] = @user.id 
    end
    redirect '/home' 
end

get '/home' do
    #day = Date.today
    #puts day.year
    #puts day.month
    puts date_chenge("12月24日")
    puts tms_date_chenge("第3週:10月17日(日) ~ 10月23日(土)")
    erb :home 
end

post '/logout' do
    session[:user] = nil
    session[:memory] = nil
    redirect '/'
end

get '/school/:id' do
    @school_id = params[:id]
    erb :tasks
end

post '/school/create' do
    @school = School.create(name: params[:name], user_id: session[:user])
    redirect '/home'
end

get '/school/:id/del' do
    school = School.find(params[:id])
    school.destroy
    erb :home
end

post '/school/:id/members/add' do
    img_url = ''
    if params[:icon]
       img = params[:icon]
       tempfile = img[:tempfile]
       upload = Cloudinary::Uploader.upload(tempfile.path)
       img_url = upload['url']
    end
    
    Member.create({
        name: params[:name],
        url: params[:url],
        icon: img_url,
        school_id: params[:id]
    })
    
    @school_id = params[:id]
    
    redirect "/school/#{params[:id]}"
end

post '/check' do
    auth_url = credentials.authorization_uri
    session[:tms_memory] = (params[:tms])
    redirect auth_url
end

get '/redirect' do
    tms_check(session[:tms_memory])
    redirect "/home"
end