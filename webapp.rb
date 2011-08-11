require "rubygems"
require "bundler/setup"
require 'sinatra'
require "sinatra/reloader"
require 'oa-oauth'
require 'yaml'
require 'databasedotcom'
require 'haml'
require 'rack-flash'
require './vmforce_strategy'

use Rack::Session::Cookie
use Rack::Flash
set :method_override, true

config = YAML.load_file("config/salesforce.yml") rescue {}
client_id = ENV['DATABASEDOTCOM_CLIENT_ID'] || config["client_id"]
client_secret = ENV['DATABASEDOTCOM_CLIENT_SECRET'] || config["client_secret"]
debugging = ENV['DATABASEDOTCOM_DEBUGGING'] || config["debugging"]
host = ENV['DATABASEDOTCOM_HOST'] || config["host"]
use OmniAuth::Strategies::Salesforce, client_id, client_secret, :host => host

module MySobjects; end;

error Databasedotcom::SalesForceError do
  exception = env['sinatra.error']
  if exception.error_code == "INVALID_SESSION_ID"
    session[:client] = nil
    flash[:notice] = "Your session expired and you were logged out!"
  else
    flash[:notice] = "#{exception.error_code}: #{exception.message}"
  end
  redirect to("/")
end

get "/" do
  if session[:client]
    haml :user_home
  else
    haml :guest_home
  end
end

get "/auth/salesforce/callback" do
  session[:client] = Databasedotcom::Client.new(:client_id => client_id, :client_secret => client_secret, :debugging => debugging, :sobject_module => MySobjects)
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
  @record = @sobject.new
  haml :new_record
end

post "/sobject/:type/create" do
  object_type = params.delete("type")
  @sobject = session[:client].materialize(object_type)
  new_object = session[:client].create(object_type, coerce_params(params))
  flash[:notice] = "A new #{object_type} was created!"
  redirect to("/sobject/#{object_type}/#{new_object.Id}")
end

get "/sobject/:type/:record_id" do
  @user = Databasedotcom::Chatter::User.find(session[:client], "me")
  sobject = params[:type]
  record_id = params[:record_id]
  @record = session[:client].materialize(sobject).find(record_id)
  haml :record
end

post "/sobject/:type/:record_id/follow" do
  me = Databasedotcom::Chatter::User.find(session[:client], session[:client].user_id)
  me.follow(params[:record_id])
  redirect to(params[:return_to])
end

get "/sobject/:type/:record_id/edit" do
  sobject = params[:type]
  record_id = params[:record_id]
  @sobject = session[:client].materialize(sobject)
  @record = @sobject.find(record_id)
  haml :edit
end

put "/sobject/:type/:record_id/update" do
  object_type = params.delete("type")
  record_id = params.delete("record_id")
  params.delete("_method")
  @sobject = session[:client].materialize(object_type)
  session[:client].update(object_type, record_id, coerce_params(params))
  flash[:notice] = "The record was updated!"
  redirect to("/sobject/#{object_type}/#{record_id}")
end

delete "/sobject/:type/:record_id" do
  session[:client].destroy(params[:type], params[:record_id])
  flash[:notice] = "The record was deleted!"
  redirect to("/sobject/#{params[:type]}")
end

get "/search" do
  @results = session[:client].search(params[:search])
  haml :results
end

get "/chatter_search" do
  @client = session[:client]
  @feed_type = "Trending Topic"
  @feed_items = Databasedotcom::Chatter::FeedItem.search(session[:client], params[:q])
  @return_to = "/chatter_search?q=#{params[:q]}"
  haml :feed
end

get "/feeds/:feed_type" do
  @client = session[:client]
  @feed_type = params[:feed_type]
  @feed_items = Databasedotcom::Chatter.const_get("#{@feed_type.camelize}Feed").find(@client, "me")
  @return_to = "/feeds/#{params[:feed_type]}"
  haml :feed
end

get "/filter_feeds/:label/:prefix" do
  @client = session[:client]
  @feed_type = params[:label]
  @feed_items = Databasedotcom::Chatter::FilterFeed.find(@client, "me", params[:prefix])
  @return_to = "/filter_feeds/#{params[:label]}/#{params[:prefix]}"
  haml :feed
end

get "/chatter/:type" do
  @entities = Databasedotcom::Chatter.const_get(params[:type][0..-2].capitalize).all(session[:client])
  @type = params[:type].capitalize
  haml :people
end

post "/chatter/users/:id/post_status" do
  Databasedotcom::Chatter::User.post_status(session[:client], params[:id], params[:status])
  redirect to("/users/#{params[:id]}")
end

post "/users/:id/follow" do
  me = Databasedotcom::Chatter::User.find(session[:client], session[:client].user_id)
  me.follow(params[:id])
  redirect to(params[:return_to])
end

get "/users/:id" do
  @user = Databasedotcom::Chatter::User.find(session[:client], params[:id])
  haml :user_page
end

get "/groups/:id" do
  @group = Databasedotcom::Chatter::Group.find(session[:client], params[:id])
  haml :group_page
end

post "/groups/:id/join" do
  Databasedotcom::Chatter::Group.find(session[:client], params[:id]).join
  redirect to(params[:return_to])
end

delete "/group-memberships/:id" do
  Databasedotcom::Chatter::GroupMembership.delete(session[:client], params[:id])
  redirect to(params[:return_to])
end

delete "/subscriptions/:id" do
  Databasedotcom::Chatter::Subscription.delete(session[:client], params[:id])
  redirect to(params[:return_to])
end

post "/feed-item/:id/comment" do
  item = Databasedotcom::Chatter::FeedItem.find(session[:client], params[:id])
  item.comment(params[:comment])
  redirect to(params[:return_to])
end

delete "/comment/:id" do
  comment = Databasedotcom::Chatter::Comment.find(session[:client], params[:id])
  comment.delete
  redirect to(params[:return_to])
end

post "/feed-item/:id/like" do
  item = Databasedotcom::Chatter::FeedItem.find(session[:client], params[:id])
  item.like
  redirect to(params[:return_to])
end

delete "/feed-item/:id/like" do
  item = Databasedotcom::Chatter::FeedItem.find(session[:client], params[:id])
  like = Databasedotcom::Chatter::Like.find(session[:client], item.raw_hash["currentUserLike"]["id"])
  like.delete
  redirect to(params[:return_to])
end

get "/conversations/:id" do
  @conversation = Databasedotcom::Chatter::Conversation.find(session[:client], params[:id], :user_id => "me")
  haml :conversation
end

post "/messages/:id/reply" do
  Databasedotcom::Chatter::Message.reply(session[:client], params[:id], params[:text])
  redirect to(params[:return_to])
end

post "/login" do
  session[:client] = Databasedotcom::Client.new("config/salesforce.yml")
  begin
    session[:client].authenticate(:username => params[:username], :password => params[:password] + params[:security_token])
  rescue Databasedotcom::SalesForceError => err
    session[:client] = nil
    flash[:notice] = err.message
  end
  redirect to("/")
end

get "/logout" do
  session[:client] = nil
  redirect to("/")
end

def coerce_params(params)
  params.each do |attr, value|
    case @sobject.field_type(attr)
      when "boolean"
        params[attr] = value.to_i != 0
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
  params
end