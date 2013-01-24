require 'sinatra'
require 'net/http'
require 'json'
require 'erubis'
require 'bcrypt'

require 'data_mapper'
DataMapper::Logger.new($stdout, :debug)
require './models/dataset'
require './models/user'
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/database.db")
DataMapper.finalize.auto_upgrade!

set :session_secret, ''
enable :sessions

helpers do
	def login?
		!session[:username].nil?
	end

	def username
		session[:username]
	end

	def password_correct? name, password, db_user=nil
		db_user ||= User.first(:name => name)
		db_user && db_user.pw_hash == BCrypt::Engine.hash_secret(password, db_user.pw_salt)			
	end

	def search_api query
		Net::HTTP.get(URI("http://imdbapi.poromenos.org/json/?name=#{URI.escape(query)}"))
	end

	def save_show name
		user = User.first(:name => username)
		if user.datasets.all(:name => name).empty?
			fav = user.datasets.new(
				:name => name,
				:touch => Time.now,
			)
			if fav.save
				return 201 # created
			else
				fav.errors.each do |error|
					puts error
				end
				return 500 # internal server error
			end
		else
			return 409 # conflict
		end
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
	 		if password_correct? params[:username], params[:password]
				session[:username] = params[:username]
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

post '/change-password' do
	if login? and params[:old_password] and params[:password] and params[:password_repeat]
		db_user = User.first(:name => username)

		if params[:password] != params[:password_repeat]
			# flash password dont match
		elsif password_correct? username, params[:password], db_user 
			# flash password wrong
		else
			# change password
			pw_salt = BCrypt::Engine.generate_salt
			pw_hash = BCrypt::Engine.hash_secret(params[:password], pw_salt)

			success = db_user.update(
				:pw_salt => pw_salt,
				:pw_hash => pw_hash 
			)

			unless success
				new_user.errors.each do |error|
					puts error
				end
				# flash errors!
			else
				# flash success
			end
		end
	end
	redirect '/'
end

post '/delete' do
	# if login? and confirm_pw is correct then delete account and logout
	if login? and params[:password]
		user = User.first(:name => username)
		if password_correct? username, params[:password], user	
			if user.datasets.all.destroy && user.destroy
				# flash "sucess"
				session[:username] = nil
			else
				# flash error
			end 
		else
			# flash password wrong
		end	
end
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
	status save_show params[:name]
end

delete '/show/:name' do
	# delete show from favorites
	user = User.first(:name => username)
	if user.datasets.all(:name => params[:name]).empty?
		status 409 # conflict
	else
		if user.datasets.all(:name => params[:name]).destroy
			status 202 # accepted
		else
			status 500 # internal server error
		end	
	end
end

put '/show/:name/:season/:episode' do
	# mark :season/:episode as watched
	user = User.first(:name => username)
	unless show = user.datasets.first(:name => params[:name])
		if (status_code = save_show params[:name]) != 201
			status = status_code
			halt
		end
	end
	show = user.datasets.first(:name => params[:name])
	id = params[:season] + '_' + params[:episode]
	episodes = show.episodes || String.new 
	if episodes.include? id
		status 409 # conflict
	else
		update = show.update(
			:episodes => episodes + id + ';',
			:touch => Time.now,
		)
		if update
			status 201 # created
		else
			watch.errors.each do |error|
				puts error
			end
			status 500 # internal server error
		end
	end
end

delete '/show/:name/:season/:episode' do
	# mark :season/:episode as unwatched
	user = User.first(:name => username)
	if show = user.datasets.first(:name => params[:name])
		id = params[:season] + '_' + params[:episode] 
		if show.episodes.include? id
			new_episodes = show.episodes.sub(/#{id};/, '')
			update = show.update(
				:episodes => new_episodes, 
				:touch => Time.now,
			)
			if update
				status 202 # accepted 
			else
				watch.errors.each do |error|
					puts error
				end
				status 500 # internal server error
			end
		else
			status 409 # conflict
		end
	else
		status 409 # conflict
	end

end

