source "http://rubygems.org"

gem 'sinatra'
gem 'sinatra-reloader'
gem 'omniauth'
gem 'haml'
gem 'rack-flash'

if Dir.exists?("../forcedotcom-api")
  gem 'forcedotcom-api', :path => "../forcedotcom-api"
else
  gem 'forcedotcom-api', :git => "https://forcedotcom-api:test1234@github.com/heroku/forcedotcom-api.git"
end

gem 'thin'

group :development do
  gem 'heroku'
end