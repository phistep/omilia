require 'sinatra'
require 'net/http'
require 'json'
require 'erubis'
require 'bcrypt' # bcrypt-ruby
require 'rack-flash' # rack-flash3

require 'data_mapper'
DataMapper::Logger.new($stdout, :debug) if development?
require './models/dataset'
require './models/user'
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/database.db")
DataMapper.finalize.auto_upgrade!

set :public_folder, File.dirname(__FILE__) + '/static'
set :session_secret, ''
enable :sessions
use Rack::Flash

helpers do
	def login?
		!session[:username].nil?
	end

	def username
		session[:username]
	end

	def password_correct? name, password, db_user=nil
		db_user ||= User.first(:name => name)
		if db_user 
			return db_user.pw_hash == BCrypt::Engine.hash_secret(password, db_user.pw_salt)			
		else
			return false
		end
	end

	def search_api query, clean=true
		if clean
			search_query = '%' + query.gsub(/\s+/, '%') + '%'
		else
			search_query = query
		end
		Net::HTTP.get(URI("http://imdbapi.poromenos.org/json/?name=#{URI.escape(search_query)}"))
	end

	def save_show name
		unless login?
			status 403 # forbidden
			halt
		end
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

	def show_info name
		return 403 unless login?
		if @datasets.first(:name => name) && episodes = @datasets.first(:name => name).episodes
			db_episodes = episodes
		else
			return 409 # conflict
		end

		result = JSON.parse(search_api(name, false))
		total = result[result.keys.first]['episodes'].count

		all_seasons = Array.new
		result[result.keys.first]['episodes'].each do |episode|
			all_seasons[episode['season']] ||= Array.new
			all_seasons[episode['season']][episode['number']] = episode['name']
		end
		all_seasons.delete_if { |x| x.nil? }
		all_seasons.each { |s| s.delete_if { |x| x.nil? } }

		if db_episodes
			watched_episodes = db_episodes.split(';')
		else
			watched_episodes = Array.new
		end

		arr_eps = Array.new
		watched_episodes.each do |ep|
			season, episode = ep.split('_')
			arr_eps.push [season.to_i, episode.to_i]
		end
		arr_eps.sort! do |x, y|
			if x[0] == y[0]
				x[1] <=> y[1]
			else
				x[0] <=> y[0]
			end
		end

		if arr_eps.last
			last_season = arr_eps.last[0]
			last_episode = arr_eps.last[1]
		else
			last_season = 1
			last_episode = 0
		end

		if all_seasons[last_season-1].count > last_episode
			next_season = last_season
			next_episode = last_episode + 1
		elsif all_seasons.count > last_season
			next_season = last_season + 1
			next_episode = 1
		else
			next_season = 0
			next_episode = 0
		end

		watched = watched_episodes.count
		unwatched = total - watched
		progress = (watched.to_f/total.to_f*100).round

		return info_hash = {
			:name => name,
			:year => result[result.keys.first]['year'],
			:next_season => next_season,
			:next_episode => next_episode,
			:next_id => "#{next_season}_#{next_episode}",
			:watched => watched,
			:unwatched => unwatched,
			:progress => progress
		}
	end
end

set :login do |status|
	condition do
		redirect '/' unless login? == status
	end
end

before do
	if params.has_key? 'search'
		redirect to("/search/#{URI.escape(params['search'])}")
	end
end

before do
	if login?
		@datasets = User.first(:name => username).datasets
	end
end

get '/' do
	@title = 'title'
	@search = ''
	if login?
		@favorites = @datasets.all(:order => [ :touch.desc ])
	end
	erb :home
end

post '/login', :login => false do
	if params[:password_repeat].empty?
		# login
		if password_correct? params[:username], params[:password]
			session[:username] = params[:username]
			flash[:notice] = "Welcome #{username}!"
		else
			flash[:error] = "Username or password wrong!"
		end
	else
		# register	
		db_user= User.first(:name => params[:username])
		
		if params[:password] != params[:password_repeat]
			flash[:error] = "Passwords did not match, try again!"
		elsif not db_user.nil?
			flash[:error] = "Unfortunately the username \"#{params[:username]}\" has been taken already. Please choose a different one."
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
				flash[:notice] = "Congratulations, #{params[:username]}, you have been registered sucessfully! Have a good time watchin'!"
			else
				new_user.errors.each do |error|
					puts error
				end
				flash[:error] = "An unkown error occured."
			end
		end
	end
	redirect '/'
end

get '/logout', :login => true do
	session[:username] = nil
	redirect '/'
end

post '/change-password', :login => true do
	if params[:old_password] and params[:password] and params[:password_repeat]
		db_user = User.first(:name => username)

		if params[:password] != params[:password_repeat]
			flash[:error] = "Passwords did not match, try again!"
			redirect request.referrer + '#change-password'
		elsif password_correct? username, params[:old_password], db_user 
			flash[:error] = "The password was wrong, try again!"
			redirect request.referrer + '#change-password'
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
				flash[:error] = "An unkown error occured."
			else
				flash[:notice] = "Your password has been changed."
			end
		end
	end
	redirect '/'
end

post '/delete', :login => true do
	# if login? and confirm_pw is correct then delete account and logout
	if params[:password]
		user = User.first(:name => username)
		if password_correct? username, params[:password], user	
			if user.datasets.all.destroy && user.destroy
				session[:username] = nil
				flash[:notice] = "Your account has been deleted :( Good Bye!"
			else
				flash[:error] = "An unkown error occured."
			end 
		else
			flash[:error] = "The password was wrong, try again!"
			redirect request.referrer + '#delete-account'
		end	
	end
	redirect '/'
end

get '/search/:query' do
	params[:query].strip!
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
			@favorites = Array.new
			if @datasets
				@datasets.all.each do |show|
					@favorites.push show.name
				end
			end
			erb :multi_result
		else
			redirect to("/show/#{URI.escape((result.keys).first)}")
		end
	end
end

get '/show/:name' do
	result = search_api params[:name], false
	if result == 'null' 
		redirect to('/search/' + params[:name].first)
	else
		result = JSON.parse(result)
		if result.key? 'shows'
			redirect to('/search/' + params[:name].first)
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
			@watched_episodes = ''
			if login? && @datasets.first(:name => @show_name) && episodes = @datasets.first(:name => @show_name).episodes
				@watched_episodes = episodes 
			end
			@collapsed = ''
			if login? && @datasets.first(:name => @show_name) && collapsed = @datasets.first(:name => @show_name).collapsed
				@collapsed = collapsed
			end
			erb :single_result
		end
	end

end

put '/show/:name', :login => true do
	# save show as favorite
	status save_show params[:name]
end

delete '/show/:name', :login => true do
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

put '/show/:name/:season/:episode', :login => true do
	# mark :season/:episode as watched
	user = User.first(:name => username)
	unless show = user.datasets.first(:name => params[:name])
		status 409 # conflict
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

delete '/show/:name/:season/:episode', :login => true do
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

get '/suggest' do
	results = Dataset.all(:fields => [:name], :unique => true)

	# enable HTTP caching
	last_modified results.max(:touch)

	shows = Array.new
	results.each do |res|
		shows.push res.name
	end
	content_type :json
	JSON.generate(shows)
end

get '/info/:show', :login => true do
	info_hash = show_info(params[:show])
	if info_hash.is_a?(Hash)
		content_type :json
		JSON.generate(info_hash)
	else
		status info_hash
	end
end

put '/collapse/:name/:season', :login => true do
	user = User.first(:name => username)
	if show = user.datasets.first(:name => params[:name])
		show = user.datasets.first(:name => params[:name])
		collapsed = show.collapsed || String.new 
		if collapsed.include? params[:season]
			status 409 # conflict
		else
			update = show.update(
				:collapsed => collapsed + params[:season] + ';',
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
	else
		status 409 # conflict
	end
end

delete '/collapse/:name/:season', :login => true do
	user = User.first(:name => username)
	if show = user.datasets.first(:name => params[:name])
		if show.collapsed.include? params[:season]
			new_collapsed = show.collapsed.sub(/#{params[:season]};/, '')
			update = show.update(
				:collapsed => new_collapsed, 
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

