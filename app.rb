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
  redirect_uri: "https://342c1446a83b4ebe8d2cbcdbc3ff8e9f.vfs.cloud9.ap-northeast-1.amazonaws.com/redirect",
  additional_parameters: {"access_type"=>"offline"}
  )

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key    = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
    session[:memory_array] = []
end

helpers do
    #ログインしているユーザーの記録
    def current_user
        User.find_by(id: session[:user])
    end
    #選択しているメンバーの記録
    def current_member(id)
        Member.find(id) 
    end
    
    def tms_check(url_array, member_array)
    credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: "592312556966-ei5l1daqd3toig4gffjgdrsds350rqo5.apps.googleusercontent.com",
    client_secret: "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",
    scope: [
        "https://www.googleapis.com/auth/drive",
        "https://spreadsheets.google.com/feeds/",
        ],
    redirect_uri: "https://342c1446a83b4ebe8d2cbcdbc3ff8e9f.vfs.cloud9.ap-northeast-1.amazonaws.com/redirect"
    #additional_parameters: {"access_type"=>"offline"}
    )
    credentials.code = params[:code]
    puts params[:code]
    credentials.fetch_access_token!
    session_google = GoogleDrive::Session.from_credentials(credentials)
    #session_google = GoogleDrive::Session.from_config("config.json")
    @error_check = !@error_check
    time = -1
    url_array.each do |url|
    time += 1
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
            ws_memory_change =  date_change(ws_memory_sub1)
            ws_month_memory, ws_day_memory = date_change(ws_memory_sub1)
            ws_date_memory = "#{date_check[0,4]}-#{ws_month_memory}-#{ws_day_memory}"
            ws_date = ws_date_memory.to_date
            puts "------"
            puts ws_date_memory
            
            puts ws_date
            rescue
                ws_date = nil
                puts "tms_error"
            end
            #[i,4]はタスク内容, [i,5]は重要度, ws_memoryは締切日時を取得している
            session[:memory].push([ws_check[i,4], ws_check[i,5], ws_memory])
            Task.create(
                content: ws_check[i,4],
                importance: importance_change(ws_check[i,5]),
                date: ws_date,
                member_id: member_array[time]
                )
            ws_memory = ""
        else
            roop = false
            break
        end
        i += 1
        
    end
    session[:member] = nil
    #puts session[:memory]
    rescue
        puts 'error'
        @error_check = true
        session[:member] = nil
    end
    end #url_array.each do 
    
    end #tmscheck
    
    #yearは8行目から取得した年情報
    def date_change(date_string)
        month = date_string.slice(/^.*月/)
        day   = date_string.slice(/月.*日/)
        month.delete!("月")
        day.delete!("月")
        day.delete!("日")
        return "#{month.to_i}","#{day.to_i}"
        
    end
    
    #TMSの日付String情報を○
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
    
    #締切チェック
    def date_check(date)
        date_ob = (date - Date.today).to_i
        if date_ob <= 7
            return 2 
        elsif date_ob <= 14   
            return 1
        else
            return 0
        end
    end
    
    def importance_change(data)
        if data == "★★★"
            return 3
        elsif data == "☆★★"
            return 2
        elsif data == "☆☆★"
            return 1
        else
            return 0
        end
    end
end

# config.jsonを読み込んでセッションを確立
# この部分はテストを兼ねている
#session_google = GoogleDrive::Session.from_config("config.json")
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
    #puts date_chenge("12月24日")
    puts tms_date_chenge("第3週:10月17日(日) ~ 10月23日(土)")
    erb :home 
end

get '/logout' do
    session[:user] = nil
    session[:memory] = nil
    session[:memory_array] = nil
    redirect '/'
end

post '/logout' do
    session[:user] = nil
    session[:memory] = nil
    session[:memory_array] = nil
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

post '/school/del' do
    school = School.find(params[:school])
    school.destroy
    redirect '/home'
end

post '/school/members/del' do
    member = Member.find(params[:id])
    member.destroy
    session[:school_memory] = params[:school]
    redirect "/school/#{session[:school_memory]}"
end

post '/school/:id/members/add' do
    img_url = ''
    if params[:icon]
       img = params[:icon]
       tempfile = img[:tempfile]
       upload = Cloudinary::Uploader.upload(tempfile.path)
       img_url = upload['url']
    end
    
    member = Member.create({
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
    session[:school_memory] = params[:school]
    puts params[:school]
    puts session[:school_memory]
    puts "ここです"
    redirect auth_url
    #redirect "/redirect"
end

get '/redirect' do
    begin
    session[:memory_array] = []
    correct_member_url = []
    correct_member_id  = []
    
    current_user.schools.find(session[:school_memory]).members.each do |member|
        tasks = member.tasks
        tasks.all.each do |task|
            task.destroy
            task.save
        end
        if member.url != ""
            correct_member_url.push(member.url)
            correct_member_id.push(member.id)
        end
    end
    #引数を配列にした
    tms_check(correct_member_url, correct_member_id)
    redirect "/school/#{session[:school_memory]}"
    rescue
    redirect '/logout'
    end
end