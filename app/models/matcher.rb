require 'levenshtein'
#include Qype

module Matcher  
  module InstanceMethods
    include Math    
    def find_matching_venues(options = {})
      venues = Rockstar::Venue.get_instance("venue.search", :venues, :venue, {:venue => title, :country => 'DE'})
      candidates = venues.collect{ |venue|
        if distance([venue.lat.to_f, venue.long.to_f], self.point.split(",").map(&:to_f)) > 0.5
          nil
        else
          candidate = Qype::Place.new
          candidate.title = venue.name      
          candidate.point = "#{venue.lat},#{venue.long}"
          candidate.phone = venue.phonenumber
          candidate.address = Address.new
          candidate.address.street = venue.street
          candidate.address.postcode = venue.postalcode
          candidate.address.city = venue.city
          candidate.external_id = venue.vid
          candidate
        end
      }
      candidates = Place.filter_by_zipcode(candidates, self)
      candidates = Place.filter_by_name(candidates, self) # not sure if it's still needed
      candidates = Place.filter_by_street(candidates, self)
      candidates = Place.filter_by_housenumber(candidates, self)
      candidates = Place.filter_by_phonenumber_and_housenumber(candidates, self)   
      candidates.sort_by{|candidate| candidate.distance_to([latitude, longitude])}
      candidates.sort_by{|candidate| Levenshtein.normalized_distance(Place.normalized_place_name(self), Place.normalized_place_name(candidate))}
    end
    
    def to_radian(degree)
      degree * Math::PI / 180
    end
    
    def distance(point1, point2)
      earth_radius = 6371
      point1[0] = to_radian(point1[0])
      point2[0] = to_radian(point2[0])
      point1[1] = to_radian(point1[1])
      point2[1] = to_radian(point2[1])
    
      lat_delta = point1[0] - point2[0]
      long_delta = point1[1] - point2[1]
      a = (sin(lat_delta/2))**2 + cos(point1[0])*cos(point2[0])*((sin(long_delta/2))**2)
      c = 2*atan2(sqrt(a), sqrt(1-a))
      d = earth_radius * c
    end
  end
  
  
  module ClassMethods
    def normalized_place_name(place)
      #TODO: remove stop words?
      place_name = place.read_attribute(:name).dup
      place_name.gsub! /(^|\s)(at)(\s|$)/i,  ' '
      place_name.gsub! /(^|\s)(the)(\s|$)/i,  ' '
      place_name.gsub! /(^|\s)(gmbh)(\s|$)/i,  ' '
      place_name.gsub! /(^|\s)(hotel)(\s|$)/i,  ' '
      place_name.gsub! /(^|\s)(restaurant)(\s|$)/i,  ' '
      place_name.gsub! /(^|\s)(cafe)(\s|$)/i,  ' '
      QueryCleaner.process place_name.downcase.delete("&,.+:´`\\'").gsub(/[-]/, ' ').squish
    end
  
    def normalized_city_name(place)
      QueryCleaner.process place.city.to_s.strip.downcase
    end
  
    def normalized_street_name(place)
      street = place.street.to_s.strip.downcase
      street.gsub!(/[\d]/, '')
      street.gsub!(/[Ss]t(rasse|raße|reet|r){1}\.?/, "st")
      street.gsub!(/[Aa](venue|v.)/, "ave")
      street.gsub!(/[Rr](oad|d.)/, "rd")
      QueryCleaner.process street.to_s
    end
  
    def normalized_housenumber(place)
      number = place.housenumber.to_s
      number.gsub!(/[^\d]/, '')
      number.strip
    end
  
    def filter_by_zipcode(candidates, place)
      postcode_matches = []
      place.zipcode = place.zipcode.to_s.strip
      candidates.each do |p|
        p.zipcode = p.zipcode.to_s.strip
        if (
          p.zipcode.blank? || place.zipcode.blank? ||
          place.zipcode == p.zipcode ||
          place.zipcode =~ /#{Regexp.escape(p.zipcode)}/ ||
          p.zipcode =~ /#{Regexp.escape(place.zipcode)}/ ||
          (
            show_feature?(:fuzzy_uk_postcode_match_filter) &&
            ! (place.zipcode.split(' ') & p.zipcode.split(' ')).empty? # Fix for Ticket 5888
          )
        )
          postcode_matches << p
        end
      end
      postcode_matches
    end
  
    def filter_by_name(candidates, place)
      candidates.inject([]) do |arr, p|
        if Levenshtein.normalized_distance(Place.normalized_place_name(place), Place.normalized_place_name(p)) < 0.57
          arr << p
        end
        arr
      end
    end
  
    def filter_by_housenumber(candidates, place)
      candidates.inject([]) do |arr, p|
        if ((place.housenumber.to_s.to_i - p.housenumber.to_s.to_i).abs < 5) || (Place.normalized_housenumber(place).blank? || Place.normalized_housenumber(p).blank? || Place.normalized_housenumber(place).to_i == 0 || Place.normalized_housenumber(p).to_i == 0)
          arr << p
        end
        arr
      end
    end
  
    def filter_by_street(candidates, place)
      return candidates if Place.normalized_street_name(place).blank?
      candidates.inject([]) do |arr, p|
        if ((Levenshtein.normalized_distance(Place.normalized_street_name(place), Place.normalized_street_name(p)) < 0.5) && !Place.normalized_street_name(p).blank?) || Place.normalized_street_name(p).blank?
          arr << p
        end
        arr
      end
    end
  
    def filter_by_phonenumber_and_housenumber(candidates, place)
      candidates.inject([]) do |arr, p|
        if (place.housenumber.to_s.to_i - p.housenumber.to_s.to_i).abs > 0
          if place.telephone_normalized == p.telephone_normalized
            arr << p
          end
        else
          arr << p
        end
        if (place.telephone_normalized.blank? || p.telephone_normalized.blank?) && !arr.include?(p)
          arr << p
        end
        if place.name == p.name && !arr.include?(p)
          arr << p
        end
        arr
      end
    end
  
    def filter_by_branded_category(candidates, place)
      candidates.inject([]) do |arr, p|
        arr << p unless (place.branded_category && p.branded_category)
        arr
      end
    end
  end
end