class CheckoutRequest {
  final int productId;
  final String buyerWallet;
  const CheckoutRequest({required this.productId, required this.buyerWallet});
  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'buyer_wallet': buyerWallet,
  };
}

class CheckoutResponse {
  final String sessionId;
  final String redirectUrl;
  const CheckoutResponse({required this.sessionId, required this.redirectUrl});
  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      sessionId: json['session_id'] as String? ?? '',
      redirectUrl: json['redirect_url'] as String? ?? '',
    );
  }
}
