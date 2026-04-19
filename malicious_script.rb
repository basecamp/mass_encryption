require 'net/http'
require 'uri'

uri = URI.parse("http://canary.domain/callback")
response = Net::HTTP.get_response(uri)