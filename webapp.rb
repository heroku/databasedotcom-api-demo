require 'sinatra'
require "sinatra/reloader"
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
  session[:client] = Forcedotcom::Api::Client.new("config/salesforce.yml")
  session[:client].authenticate(request.env['omniauth.auth'])
  redirect to("/")
end

get "/sobject/:type" do
  @sobject = params[:type]
  haml :sobject
end

get "/sobject/:type/:record_id" do
  sobject = params[:type]
  record_id = params[:record_id]
  @record = session[:client].materialize(sobject).find(record_id)
  haml :record
end
