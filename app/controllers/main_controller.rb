class MainController < ApplicationController
  include Qype
  before_filter :set_qype_client
  before_filter :initialize_geo

  def index    
    @events = []
    #@events = geo.events(:location => 'Hamburg', :limit => 50)
  end
  
  def venues
    @venues = @qype.search_places("Music Venues", "Hamburg")
  end
  
  def venue
    @venue = Place.get(@qype, params[:id])
    lat , long = @venue.point.split(",")
    @nearby_events = @geo.events(:lat => lat, :long => long, :distance => 2)
  end
  
  def search
    @events = []
    @venues = @qype.search_places(params[:name], params[:location])
  end

  def map
    lat, long = params[:id].split(",")
    @events = @geo.events(:lat => lat, :long => long, :distance => 2)
    render :layout => false
  end
    
  def event
    
  end
  
  private  
  def set_qype_client
    @qype = Qype::Client.new('uap1OQ6K8kh9fOBVElcQyQ', 'x6za13JgoHSgPJzn9LANQPgLs33ztyuxMXF34KAtXg')
  end

  def initialize_geo
    @geo = Rockstar::Geo.new
  end
end
