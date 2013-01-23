require 'sinatra'
require 'net/http'
require 'json'
require 'erubis'
require 'bcrypt'

require 'data_mapper'
DataMapper::Logger.new($stdout, :debug)
require './models/data-set'
require './models/user'
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/database.db")
DataMapper.finalize.auto_upgrade!

set :session_secret, ''
enable :sessions

helpers do
	def login?
		!session[:username].nil?
	end

	def search_api query
		Net::HTTP.get(URI("http://imdbapi.poromenos.org/json/?name=#{URI.escape(query)}"))
	end
end

before do
	if params.has_key? 'search'
		redirect to("/search/#{URI.escape(params['search'])}")
	end
end

get '/' do
	@title = 'title'
	@search = ''
	erb :home
end

post '/login' do
	unless login? #or params[:username] or params[:password] or params[:password_repeat].nil?
		if params[:password_repeat].empty?
			# login
			db_user = User.first(:name => params[:username])
			if !db_user.nil? and db_user.pw_hash == BCrypt::Engine.hash_secret(params[:password], db_user.pw_salt)
	 			session[:username] = db_user.name
				# flash success
			else
				# flash username/pw wrong
			end
		else
			# register	
			db_user= User.first(:name => params[:username])
			
			if params[:password] != params[:password_repeat]
				# flash pw not matching
			elsif not db_user.nil?
				# flash username taken
			else
				pw_salt = BCrypt::Engine.generate_salt
				pw_hash = BCrypt::Engine.hash_secret(params[:password], pw_salt)

				new_user = User.new(
					:name => params[:username],
					:pw_salt => pw_salt,
					:pw_hash => pw_hash, 
				)

				if new_user.save
					session[:username] = params[:username]
					# flash sucess
				else
					new_user.errors.each do |error|
						puts error
					end
					# flash errors!
				end
			end

		end
	end
	redirect '/'
end

get '/logout' do
	session[:username] = nil if login?
	redirect '/'
end

post '/delete' do
	# if login? and confirm_pw is correct then delete account and logout
	# session[:username] = nil
	redirect '/'
end

post '/change-password' do
	# if login? and old_pw is correct and new_pw == new_pw_repeat then change password
	redirect '/'
end

get '/search/:query' do
	result = search_api params[:query]
	if result == 'null'
		@title = 'No Results'
		@search = params[:query]
		erb :no_results
	else
		result = JSON.parse(result)
		if result.key? 'shows'
			@shows = result['shows']
			@search = params[:query]
			@title = "Results for \"#{@search}\""
			erb :multi_result
		else
			@show_name = (result.keys).first
			redirect to("/show/#{URI.escape(@show_name)}")
		end
	end
end

get '/show/:name' do
	result = search_api params[:name]
	if result == 'null' 
		redirect to("/search/#{URI.escape(params[:name].first)}")
	else
		result = JSON.parse(result)
		if result.key? 'shows'
			redirect to("/search/#{URI.escape(params[:name].first)}")
		else
			@show_name = (result.keys).first
			@year = result[@show_name]['year']
			@seasons = Array.new
			result[@show_name]['episodes'].each do |episode|
				@seasons[episode['season']] ||= Array.new
				@seasons[episode['season']][episode['number']] = episode['name']
			end
			@seasons.delete_if { |x| x.nil? }
			@seasons.each { |s| s.delete_if { |x| x.nil? } }
			
			@title = @show_name
			@search = '' 
			erb :single_result
		end
	end

end

put '/show/:name' do
	# save show as favorite
end

delete '/show/:name' do
	# delete show from favorites
end

put '/show/:name/:season/?:episode?' do
	# mark :season/:episode as watched
end

delete 'show/:name/:season/?:episode?' do
	# mark :season/:episode as unwatched
end

