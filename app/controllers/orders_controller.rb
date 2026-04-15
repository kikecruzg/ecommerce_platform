class OrdersController < ApplicationController
  def create
    customer = Customer.find(params[:customer_id])
    items    = params.require(:items)
    address  = params.require(:shipping_address)

    # Geocode the shipping address (Mock)
    location = GeocodingService.geocode(address)

    # Find the closest warehouse that can fulfill all items
    warehouse = WarehouseSelectionService.find(items: items, lat: location.lat, lng: location.lng)
    return render json: { error: "No warehouse can fulfill this order" }, status: :unprocessable_entity if warehouse.nil?

    # Load products
    product_ids = items.map { |i| i[:product_id] }
    products    = Product.where(id: product_ids).index_by(&:id)

    total = items.sum do |item|
      product = products[item[:product_id].to_i]
      return render json: { error: "Product #{item[:product_id]} not found" }, status: :not_found unless product

      product.price * item[:quantity].to_i
    end

    # Charge the customer
    payment = PaymentService.charge(
      credit_card_number: customer.credit_card_number,
      amount: total,
      description: "Order for #{customer.name}"
    )

    return render json: { error: "Payment failed" }, status: :payment_required unless payment.success

    # Persist the order and decrement inventory inside a transaction
    order = ActiveRecord::Base.transaction do
      order = Order.create!(
        customer: customer,
        warehouse: warehouse,
        shipping_address: address,
        shipping_lat: location.lat,
        shipping_lng: location.lng,
        total_amount: total,
        payment_id: payment.payment_id,
        status: :confirmed
      )

      items.each do |item|
        product        = products[item[:product_id].to_i]
        quantity       = item[:quantity].to_i

        order.order_items.create!(
          product: product,
          quantity: quantity,
          unit_price: product.price
        )

        # Decrement inventory with pessimistic lock to prevent race conditions
        inventory = WarehouseInventory.lock.find_by!(warehouse: warehouse, product: product)
        inventory.decrement!(:quantity, quantity)
      end

      order
    end

    render json: order_json(order), status: :created
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def order_json(order)
    {
      id: order.id,
      status: order.status,
      warehouse_id: order.warehouse_id,
      total_amount: order.total_amount,
      payment_id: order.payment_id,
      shipping_address: order.shipping_address,
      items: order.order_items.map do |item|
        { product_id: item.product_id, quantity: item.quantity, unit_price: item.unit_price }
      end
    }
  end
end
