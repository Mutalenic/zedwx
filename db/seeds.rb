# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Location.destroy_all

zambian_cities = [
  { name: "Lusaka", latitude: -15.3875, longitude: 28.3228 },
  { name: "Ndola", latitude: -12.9693, longitude: 28.6366 },
  { name: "Kitwe", latitude: -12.8037, longitude: 28.2136 },
  { name: "Kabwe", latitude: -14.4432, longitude: 28.4513 },
  { name: "Livingstone", latitude: -17.8531, longitude: 25.8625 }
]

zambian_cities.each { |city| Location.create!(city) }

puts "Seeded #{Location.count} Zambian cities!"
