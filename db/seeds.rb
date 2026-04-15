puts "Seeding customers..."

customers = [
  { name: "Alice Johnson",  email: "alice@example.com",  credit_card_number: "4111111111111111" },
  { name: "Bob Smith",      email: "bob@example.com",    credit_card_number: "4242424242424242" },
  { name: "Carol Williams", email: "carol@example.com",  credit_card_number: "5500005555555559" }
]

customers.each { |attrs| Customer.find_or_create_by!(email: attrs[:email]) { |c| c.assign_attributes(attrs) } }

puts "Seeding products..."

products = [
  { name: "Wireless Headphones", sku: "WH-001", price: 79.99 },
  { name: "Mechanical Keyboard", sku: "MK-002", price: 129.99 },
  { name: "USB-C Hub",           sku: "UC-003", price: 49.99 },
  { name: "Webcam HD",           sku: "WC-004", price: 89.99 },
  { name: "Mouse Pad XL",        sku: "MP-005", price: 24.99 }
]

products.each { |attrs| Product.find_or_create_by!(sku: attrs[:sku]) { |p| p.assign_attributes(attrs) } }

puts "Seeding warehouses..."

# Warehouses in different US cities with real coordinates
warehouses = [
  { name: "NYC Warehouse",  address: "100 Warehouse Ave, New York, NY",      latitude: 40.7128,  longitude: -74.0060  },
  { name: "LA Warehouse",   address: "200 Storage Blvd, Los Angeles, CA",    latitude: 34.0522,  longitude: -118.2437 },
  { name: "Chicago Hub",    address: "300 Depot St, Chicago, IL",            latitude: 41.8781,  longitude: -87.6298  },
  { name: "Houston Center", address: "400 Logistics Rd, Houston, TX",        latitude: 29.7604,  longitude: -95.3698  },
  { name: "Seattle Depot",  address: "500 Fulfillment Way, Seattle, WA",     latitude: 47.6062,  longitude: -122.3321 }
]

warehouses.each { |attrs| Warehouse.find_or_create_by!(name: attrs[:name]) { |w| w.assign_attributes(attrs) } }

puts "Seeding warehouse inventories..."

wh_nyc     = Warehouse.find_by!(name: "NYC Warehouse")
wh_la      = Warehouse.find_by!(name: "LA Warehouse")
wh_chicago = Warehouse.find_by!(name: "Chicago Hub")
wh_houston = Warehouse.find_by!(name: "Houston Center")
wh_seattle = Warehouse.find_by!(name: "Seattle Depot")

p_headphones = Product.find_by!(sku: "WH-001")
p_keyboard   = Product.find_by!(sku: "MK-002")
p_hub        = Product.find_by!(sku: "UC-003")
p_webcam     = Product.find_by!(sku: "WC-004")
p_mousepad   = Product.find_by!(sku: "MP-005")

# NYC has all products
[p_headphones, p_keyboard, p_hub, p_webcam, p_mousepad].each_with_index do |product, i|
  WarehouseInventory.find_or_create_by!(warehouse: wh_nyc, product: product) { |inv| inv.quantity = (i + 1) * 10 }
end

# LA is missing the keyboard
[p_headphones, p_hub, p_webcam, p_mousepad].each_with_index do |product, i|
  WarehouseInventory.find_or_create_by!(warehouse: wh_la, product: product) { |inv| inv.quantity = (i + 1) * 5 }
end

# Chicago only has headphones and keyboards
[p_headphones, p_keyboard].each_with_index do |product, i|
  WarehouseInventory.find_or_create_by!(warehouse: wh_chicago, product: product) { |inv| inv.quantity = (i + 1) * 20 }
end

# Houston has all products with high stock
[p_headphones, p_keyboard, p_hub, p_webcam, p_mousepad].each_with_index do |product, i|
  WarehouseInventory.find_or_create_by!(warehouse: wh_houston, product: product) { |inv| inv.quantity = (i + 1) * 50 }
end

# Seattle has all products but low stock
[p_headphones, p_keyboard, p_hub, p_webcam, p_mousepad].each_with_index do |product, i|
  WarehouseInventory.find_or_create_by!(warehouse: wh_seattle, product: product) { |inv| inv.quantity = i + 1 }
end

puts "Done! #{Customer.count} customers, #{Product.count} products, #{Warehouse.count} warehouses."
