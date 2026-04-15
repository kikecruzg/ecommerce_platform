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

puts "Done! #{Customer.count} customers, #{Product.count} products."
