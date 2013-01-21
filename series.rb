require 'sinatra'
require 'net/http'
require 'json'
require 'erubis'

get '/' do
	# if session[logged_in]
	#	overview over all series, logout button, delete account button
	# else
	#	show landing page
	if params.has_key? 'search'
		redirect to("/search/#{URI.escape(params['search'])}")
	else
		@title = 'title'
		@search = ''
		erb :home
	end
end

post '/login' do
	# if !session[logged_in]
	#	if pw_repeat.empty?
	#		login
	# 	else
	#		register
	# else
	#	redirect /
end

get '/logout' do
	# if session[logged_in]
	#	logout
	# else
	#	redirect /
end

post '/delete' do
	# if session[logged_in]
	#	if confirm_pw is correct
	#		delete account
	#		logout
	#	else
	#		redirect with alert
	# else
	#	redirect /
end

get '/search/*' do
	# search IMDb API for params[:splat]
	# display results
	result = Net::HTTP.get(URI("http://imdbapi.poromenos.org/json/?name=#{URI.escape(params[:splat].first)}"))
	if result == 'null'
		@title = 'No Results'
		@search = params[:splat].first
		erb :no_result
	else
		result = JSON.parse(result)
		if result.key? 'shows'
			@shows = result['shows']
			@search = params[:splat].first
			@title = "Results for \"#{@search}\""
			erb :multi_result
		else
			@show_name = (result.keys).first
			redirect to("/show/#{URI.escape(@show_name)}")
		end
	end
end

get '/show/:name' do
	result = Net::HTTP.get(URI("http://imdbapi.poromenos.org/json/?name=#{URI.escape(params[:name].first)}"))
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

put '/show/:name/:season/:episode?' do
	# mark :season/:episode as watched
end

delete 'show/:name/:season/:episode?' do
	# mark :season/:episode as unwatched
end

__END__

@@ layout
<!DOCTYPE html>
<html>
<head>
	<title><%= @title %></title>
</head>
<body>
	<form  method="get" action="/">Search: <input type="text" name="search" value="<%== @search %>"><input type="submit" value="Go"> ('%' is a wildcard)</form>
	<%= yield %>
</body>
</html>

@@ home 

@@ no_result
<h1>No results</h1>

@@ multi_result
<h1>Results for "<%== @search %>"</h1>
<ul>
<% @shows.each do |show| %>
	<li><a href="/?search=<%= URI.escape(show['name']) %>"><%= show['name'] %></a> (<%= show['year'].to_s %>)</li>
<% end %>
</ul>

@@ single_result
<h1><%= @show_name %> <small>(<%= @year %>)</small></h1>
<ol>
<% @seasons.each_with_index do |season, i| %>
	<li><input type="checkbox" id="s<%= i %>"> <label for="s<%= i %>">Season</label>
		<ol>
		<% season.each_with_index do |episode, j| %>
			<li><input type="checkbox" id="<%= i %>_<%= j %>"> <label for="<%= i %>_<%= j %>"><%= episode %></label></li>
		<% end %>
		</ol>
	</li>
<% end %>
</ol>

