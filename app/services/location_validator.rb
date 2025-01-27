class LocationValidator
  def self.valid_location?(location)
    return false unless location.is_a?(String)
    ZedWx::SUPPORTED_LOCATIONS.key?(location.capitalize)
  end

  def self.get_coordinates(location)
    ZedWx::SUPPORTED_LOCATIONS[location.capitalize]
  end

  def self.supported_locations
    ZedWx::SUPPORTED_LOCATIONS.keys
  end
end