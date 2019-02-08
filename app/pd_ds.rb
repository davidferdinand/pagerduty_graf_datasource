require 'sinatra'
require 'httparty'
require 'json'
require_relative './services_list'
require_relative './query'


services = Services.new
list = services.services_list()

get '/' do
  200
end

post '/search' do
  list
end

post '/query' do
  query = Query.new request
  query.output
end
