require 'sinatra'
require 'oa-oauth'
require 'yaml'
require 'rubygems'
require 'forcedotcom/api'

use Rack::Session::Cookie

config = YAML.load_file("config/salesforce.yml")
use OmniAuth::Strategies::Salesforce, config["client_secret"], config["client_id"]

get "/" do
  if session[:client]
    haml :user_home
  else
    haml :guest_home
  end
end

get "/auth/salesforce/callback" do
  auth_hash = request.env['omniauth.auth']
  session[:client] = Forcedotcom::Api::Client.new(auth_hash)
  redirect to("/")
end
