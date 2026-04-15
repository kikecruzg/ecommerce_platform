# Mock payment service. In production this would call an external payments API.
# The mock always succeeds and returns a generated payment ID.
class PaymentService
  Result = Data.define(:success, :payment_id, :error_message)

  def self.charge(credit_card_number:, amount:, description:)
    new.charge(credit_card_number: credit_card_number, amount: amount, description: description)
  end

  def charge(credit_card_number:, amount:, description:)
    # Simulate network latency
    # sleep(0.1)

    Result.new(
      success: true,
      payment_id: "pay_#{SecureRandom.hex(12)}",
      error_message: nil
    )
  end
end
