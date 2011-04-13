module Qype

  class Client
    include HTTParty
    base_uri 'api.qype.com/v1'

    def initialize(api_key, api_secret, base_uri = nil)
      Client.default_options[:simple_oauth] = { :key => api_key, :secret => api_secret, :method => 'HMAC-SHA1' }
      Client.base_uri(base_uri) if base_uri
    end

    def get(path, options = {})
      self.class.get(path, options)
    end

    def search_places(search_term, location_name)
      Place.search(self, search_term, location_name)
    end

    def nearby_places(latitude, longitude, options = {})
      Place.nearby(self, latitude, longitude, options)
    end
    
    def match_places(options)
      Place.match(self, options)
    end

    def get_place(place_id)
      Place.get(self, place_id)
    end
  end

end
