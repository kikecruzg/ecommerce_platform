class WarehouseSelectionService
  # items: array of { product_id:, quantity: }
  # lat/lng: coordinates of the shipping address
  # Returns the closest Warehouse that can fulfill all items, or nil if none exists
  def self.find(items:, lat:, lng:)
    new.find(items: items, lat: lat, lng: lng)
  end

  def find(items:, lat:, lng:)
    eligible = eligible_warehouses(items)
    return nil if eligible.empty?

    eligible.min_by { |w| haversine_distance(lat, lng, w.latitude, w.longitude) }
  end

  private

  def eligible_warehouses(items)
    product_ids       = items.map { |i| i[:product_id].to_i }
    required_quantity = items.each_with_object({}) { |i, h| h[i[:product_id].to_i] = i[:quantity].to_i }

    # Load all relevant inventory rows in one query
    inventories = WarehouseInventory
      .where(product_id: product_ids)
      .select(:warehouse_id, :product_id, :quantity)

    # Group by warehouse and keep only those that can fulfill every item
    by_warehouse = inventories.group_by(&:warehouse_id)

    eligible_ids = by_warehouse.filter_map do |warehouse_id, invs|
      inv_by_product = invs.index_by(&:product_id)

      can_fulfill = product_ids.all? do |product_id|
        inv = inv_by_product[product_id]
        inv && inv.quantity >= required_quantity[product_id]
      end

      warehouse_id if can_fulfill
    end

    Warehouse.where(id: eligible_ids)
  end

  # Haversine formula — returns distance in kilometers
  def haversine_distance(lat1, lng1, lat2, lng2)
    earth_radius_km = 6371.0

    dlat = to_rad(lat2.to_f - lat1.to_f)
    dlng = to_rad(lng2.to_f - lng1.to_f)

    a = Math.sin(dlat / 2)**2 +
        Math.cos(to_rad(lat1.to_f)) * Math.cos(to_rad(lat2.to_f)) * Math.sin(dlng / 2)**2

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius_km * c
  end

  def to_rad(degrees)
    degrees * Math::PI / 180
  end
end
