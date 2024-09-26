require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'
require 'geocoder'

enable :sessions
@viewGeneral = false
#ログイン判定関数
def logged_in?
    !!session[:user_id]
end

#距離測定関数
def distance(lat1, lon1, lat2, lon2)
  Geocoder::Calculations.distance_between([lat1, lon1], [lat2, lon2], units: :km)
end

#ファイルを保存して，画像名を返り値とする関数
def save_file(file)
    if file.nil? || file[:tempfile].size == 0
        filename = "default_icon.jpeg" # デフォルトのアイコン名を返す
    else
        filename = file[:filename]
        filepath = "./public/img/#{filename}"
    
        File.open(filepath, 'wb') do |f|
            f.write(file[:tempfile].read)
        end
    end
    return filename
end

#APIを取得して，市町村を特定
def get_city_name(latitude, longitude)
    url = "https://nominatim.openstreetmap.org/reverse?lat=#{latitude}&lon=#{longitude}&format=json"
    response = HTTParty.get(url)
    
    if response.code != 200
        puts "APIリクエスト失敗: #{response.code}"
        return nil
    else
        puts "APIリクエスト成功"
        data = response.parsed_response
        city = data['address']['city'] || data['address']['town'] || data['address']['village']
        return city
    end
end


#全ての処理の前に実行する処理
before do
  @city = session[:city]
end


get '/' do
    if logged_in?
        @user = User.find(session[:user_id])
        @viewGeneral = session[:viewGeneral]
        if @viewGeneral
            # 一般の投稿: 現在のコードをそのまま利用
            if session[:latitude] && session[:longitude]
                user_lat = session[:latitude].to_f
                user_lon = session[:longitude].to_f
                @contents = Content.all.select do |content|
                    if content.latitude && content.longitude
                        distance(user_lat, user_lon, content.latitude, content.longitude) <= 10
                    else
                        false
                    end
                end.sort_by(&:created_at).reverse  # 作成日時でソートして逆順（新しい順）に
            else
                @contents = []
            end
        else
            # フォロー中の人の投稿のみ取得
            followed_users_ids = @user.follows.pluck(:follow_user_id) # フォロー中の人のIDリスト取得
            @contents = Content.where(user_id: followed_users_ids).order(created_at: :desc) # 作成日時で降順にソート
        end

        erb :index
    else
        redirect '/signin'
    end
end


post '/viewFollow' do
    session[:viewGeneral] = false
    redirect '/'
end

post '/viewGeneral' do
    session[:viewGeneral] = true
    redirect '/'
end


#位置情報取得処理
post '/save_location' do
    session[:latitude] = params[:latitude].to_f
    session[:longitude] = params[:longitude].to_f
    session[:city] = get_city_name(session[:latitude], session[:longitude])
    
    #デバッグ操作
    p session[:latitude]
    p session[:longitude]
    redirect '/'
end

#サインイン画面
get '/signin' do
    erb :signin
end

#サインイン処理
post '/signin' do
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user_id] = user.id
        @user = user
        redirect '/'
    else
        redirect '/signin'
    end
end

#サインアップ画面
get '/signup' do
    erb :signup
end

#サインアップ処理
post '/signup' do
    puts params.inspect
    icon_name = save_file(params[:icon])
    user = User.create(name: params[:name], email: params[:email], password: params[:password], icon: icon_name)
    if user.persisted?
        session[:user_id] = user.id
        redirect '/'
    else
        redirect '/signup'
    end
end

#サインアウト処理
get '/signout' do
    session[:user_id] = nil
    redirect '/'
end

post '/like' do
    Like.create(user_id: session[:user_id], content_id: params[:content_id])
    redirect '/'
end

#フォロー処理
post '/follow' do
    Follow.create(user_id: session[:user_id], follow_user_id: params[:follow_user_id])
    redirect '/'
end

#投稿作成画面
get '/create_content' do
    @user = User.find(session[:user_id])
    erb :create_content
end

#投稿作成処理
post '/create_content' do
    @user = User.find(session[:user_id])

    # 位置情報を Float に変換する
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f
    city = get_city_name(latitude, longitude)
    # 位置情報が無効な場合はデフォルト値を設定する
    latitude = nil if latitude.zero?
    longitude = nil if longitude.zero?
    
    picture = save_file(params[:picture]) || 'default.jpg'

    @user.contents.create(
        user_id: @user.id,
        content: params[:content],
        picture: picture,
        likenumber: 0,
        latitude: latitude,
        longitude: longitude,
        city: city
    )
    redirect '/'
end

#マイプロフィール画面を表示(投稿一覧)
get '/myprofile/content' do
    @user = User.find(session[:user_id])
    @profile = @user.contents
    @follow = @user.follows
    erb :profile
end

#マイプロフィール画面を表示(植物表示)
get '/myprofile/growup' do
    
end

#id番目の人のプロフィールを表示
get '/profile/:id' do
    @user = User.find(params[:id])
    erb :profile
end

=begin
post '/create_content' do
    user = User.find(session[:user_id])

    # 位置情報を Float に変換する
    latitude = params[:latitude].to_f
    longitude = params[:longitude].to_f

    # 位置情報が無効な場合はデフォルト値を設定する
    latitude = nil if latitude.zero?
    longitude = nil if longitude.zero?

    picture = save_file(params[:picture]) || 'default.jpg'

    user.contents.create(
        user_id: user.id,
        content: params[:content],
        picture: picture,
        likenumber: 0,
        latitude: latitude,
        longitude: longitude
    )
    redirect '/'
end
=end

#id番目の人のフォロー一覧
get '/follows/:id' do
    @user = User.find(session[:user_id])
    @follows = @user.follows
    erb :follow
end

#id番目の人のフォロワー一覧
get '/followers/:id' do
    @user = User.find(session[:user_id])
    @followers = Follow.where(follow_user_id: @user.id)
    erb :follower
end

get '/edit' do
    @user = User.find(session[:user_id])
    erb :edit
end

post '/edit' do
    
end


get '/r' do
    User.delete_all
    Content.delete_all
    Follow.delete_all
    Like.delete_all
end