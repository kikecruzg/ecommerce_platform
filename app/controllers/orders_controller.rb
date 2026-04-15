class OrdersController < ApplicationController
  def create
    customer = Customer.find(params[:customer_id])
    items    = params.require(:items)
    address  = params.require(:shipping_address)

    # Geocode the shipping address (Mock)
    location = GeocodingService.geocode(address)

    product_ids = items.map { |i| i[:product_id] }
    products    = Product.where(id: product_ids).index_by(&:id)

    total = items.sum do |item|
      product = products[item[:product_id].to_i]
      return render json: { error: "Product #{item[:product_id]} not found" }, status: :not_found unless product

      product.price * item[:quantity].to_i
    end

    payment = PaymentService.charge(
      credit_card_number: customer.credit_card_number,
      amount: total,
      description: "Order for #{customer.name}"
    )

    return render json: { error: "Payment failed" }, status: :payment_required unless payment.success

    # Persist the order inside a transaction
    order = ActiveRecord::Base.transaction do
      order = Order.create!(
        customer: customer,
        shipping_address: address,
        shipping_lat: location.lat,
        shipping_lng: location.lng,
        total_amount: total,
        payment_id: payment.payment_id,
        status: :confirmed
      )

      items.each do |item|
        order.order_items.create!(
          product: products[item[:product_id].to_i],
          quantity: item[:quantity].to_i,
          unit_price: products[item[:product_id].to_i].price
        )
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
      total_amount: order.total_amount,
      payment_id: order.payment_id,
      shipping_address: order.shipping_address,
      items: order.order_items.map do |item|
        { product_id: item.product_id, quantity: item.quantity, unit_price: item.unit_price }
      end
    }
  end
end
