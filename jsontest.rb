require 'net/http'
require 'json'
require 'httparty'

# get imdb id for each show from tv maze, use iD then to search for them on eztv API
def latest_episode(name)

  string = Net::HTTP.get('api.tvmaze.com', "/singlesearch/shows?q=#{name}")

  parsed = JSON.parse(string)

  ep_url=  parsed["_links"]["previousepisode"]['href']

  response = HTTParty.get(ep_url)

  parsed = JSON.parse(response.body)

  puts "#{parsed["season"]} and #{parsed["number"]}"
  
end

