# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def place_attributes(place)
    options = {}
    options.merge!(:name => place.name) unless place.name.blank?
    #don't filter by phones - they are strange in last fm
    #options.merge!(:phone => place.phonenumber) unless place.phonenumber.blank?
    options.merge!(:street => place.street) unless place.street.blank?
    options.merge!(:city => place.city) unless place.city.blank?
    options.merge!(:postcode => place.postalcode) unless place.postalcode.blank?
    options.merge!(:point => "#{place.lat},#{place.long}") unless place.lat.blank? or place.long.blank?
  end
end
