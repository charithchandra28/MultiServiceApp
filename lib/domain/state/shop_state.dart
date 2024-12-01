import '../../data/models/shop_model.dart';

class ShopState {
  final bool isLoading;
  final String? errorMessage;
  final List<ShopModel> shops;
  final bool hasReachedMax;

  ShopState({
    this.isLoading = false,
    this.errorMessage,
    this.shops = const [],
    this.hasReachedMax = false,
  });

  ShopState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ShopModel>? shops,
    bool? hasReachedMax,
  }) {
    return ShopState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      shops: shops ?? this.shops,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}
