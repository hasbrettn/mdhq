require 'rubygems'
require 'sinatra'
require 'json'
require 'dm-core'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-serializer'

if development? # Defaults to true. Configured via the RACK_ENV environment variable
  require 'sinatra/reloader'
  require 'debugger'
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
  Debugger.settings[:reload_source_on_change] = true
end

configure :development do
  set :datamapper_url, "sqlite3://#{File.dirname(__FILE__)}/notification.sqlite3"
end
configure :production do
  set :datamapper_url, "sqlite3://#{File.dirname(__FILE__)}/notification.production.sqlite3"
end
configure :test do
  set :datamapper_url, "sqlite3://#{File.dirname(__FILE__)}/notification-test.sqlite3"
end

before do
  content_type 'application/json'
end

DataMapper.setup(:default, settings.datamapper_url)

class Notification
  include DataMapper::Resource

  Notification.property(:id, Serial)
  Notification.property(:title, Text, :required => true)
  Notification.property(:message, Text, :required => true)
  Notification.property(:image_url, Text, :default=> "https://cdn3.iconfinder.com/data/icons/internet-and-web-4/78/internt_web_technology-13-512.png")
  Notification.property(:email_address, Text, :required => true)

  def to_json(*a)
   {
      'id' => self.id,
      'title' => self.title,
      'message' => self.message,
      'image_url' => self.image_url,
      'email_address' => self.email_address
   }.to_json(*a)
  end
end

DataMapper.finalize
Notification.auto_upgrade!

# Tack on the callback if the client specifies a callback
def jsonp(json)
  params[:callback] ? "#{params[:callback]}(#{json})" : json
end

get '/notification/all' do
  data = Notification.all
  jsonp(data.to_json)
end

# Download one item
get '/notification/:id' do
  item = Notification.get(params[:id])
  
  halt 404 if item.nil?
  jsonp(item.to_json)
end

# Create/insert a new notification. Will give you back an id
put '/notification' do
  # If anything else needs to read request.body, rewind it here
  data = JSON.parse(request.body.read)

  if data.nil? || data['title'].nil? || data['message'].nil? || data['email_address'].nil?
    halt 400
  end

  item = Notification.create(
              :title => data['title'],
              :message => data['message'],
              :image_url => data['image_url'],
              :email_address => data['email_address'])

  halt 500 unless item.save

  # By convention the header returned should be the url for the new resource
  [201, {'Location' => "/notification/#{item.id}"}, jsonp(item.to_json)]
end

# Update a single record. Only attributes specified in the request will be updated from parameters, others are ignored
post '/notification/:id' do
  # Be sure to rewind the request if it is read from before this point
  data = JSON.parse(request.body.read)
  halt 400 if data.nil?
  
  item = Notification.get(params[:id])
  halt 404 if item.nil?

  %w(title message image_url email_address).each do |key|
    if !data[key].nil? && data[key] != item[key]
      item[key] = data[key]
    end
  end

  halt 500 unless item.save
  jsonp(item.to_json)
end

# Remove a record - This should be secured in a production environment via authentication
delete '/notification/:id' do
  item = Notification.get(params[:id])
  halt 404 if item.nil?
  
  halt 500 unless item.destroy
  204
end

