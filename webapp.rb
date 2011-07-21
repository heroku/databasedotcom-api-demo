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

get "/sobject/:type/new" do
  @sobject = session[:client].materialize(params[:type])
  haml :new_record
end

post "/sobject/:type/create" do
  object_type = params.delete("type")
  @sobject = session[:client].materialize(object_type)
  params.each do |attr, value|
    case @sobject.field_type(attr)
      when "boolean"
        params[attr] = (value.casecmp("true") == 0)
      when "multipicklist"
        params[attr] = [value]
      when "currency", "percent", "double"
        params[attr] = value.to_f
      when "date"
        params[attr] = Date.parse(value) rescue Date.today
      when "datetime"
        params[attr] = DateTime.parse(value) rescue DateTime.now
    end
  end
  session[:client].create(object_type, params)
  redirect to("/sobject/#{object_type}")
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