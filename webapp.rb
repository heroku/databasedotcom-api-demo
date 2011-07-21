require 'sinatra'
require "sinatra/reloader"
require 'oa-oauth'
require 'yaml'
require 'rubygems'
require 'forcedotcom/api'
require 'haml'

use Rack::Session::Cookie
set :method_override, true

config = YAML.load_file("config/salesforce.yml")
use OmniAuth::Strategies::Salesforce, config["client_id"], config["client_secret"]

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
  @names_or_ids = session[:client].query("SELECT Name,Id FROM #{@sobject}") rescue session[:client].query("SELECT Id FROM #{@sobject}")
  haml :sobject
end

get "/sobject/:type/:record_id" do
  sobject = params[:type]
  record_id = params[:record_id]
  @record = session[:client].materialize(sobject).find(record_id)
  haml :record
end

delete "/sobject/:type/:record_id" do
  session[:client].delete(params[:type], params[:record_id])
  session[:message] = "The record was deleted!"
  redirect to("/sobject/#{params[:type]}")
end

post "/login" do
  session[:client] = Forcedotcom::Api::Client.new("config/salesforce.yml")
  begin
    session[:client].authenticate(:username => params[:username], :password => params[:password] + params[:security_token])
  rescue Forcedotcom::Api::SalesForceError => err
    session[:client] = nil
    session[:message] = err.message
  end
  redirect to("/")
end

get "/logout" do
  session[:client] = nil
  redirect to("/")
end