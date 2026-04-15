# Mock geocoding service
class GeocodingService
  Result = Data.define(:lat, :lng)

  def self.geocode(address)
    new.geocode(address)
  end

  def geocode(address)
    lat = rand(-90.0..90.0).round(6)
    lng = rand(-180.0..180.0).round(6)
    Result.new(lat: lat, lng: lng)
  end
end
