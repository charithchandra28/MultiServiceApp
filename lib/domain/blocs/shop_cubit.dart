import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/shop_model.dart';
import '../../data/repositories/shop_repository.dart';
import '../state/shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository repository;
  int _currentPage = 0;
  final int _pageSize = 10;

  ShopCubit({required this.repository}) : super(ShopState());

  Future<void> fetchShops(String serviceType) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final shops = await repository.fetchShopsByServiceType(serviceType);
      print("shop $shops");
      emit(state.copyWith(isLoading: false, shops: shops));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading shops: $e',
      ));
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.hasReachedMax) return;
    emit(state.copyWith(isLoading: true));
    try {
      final newShops = await repository.fetchNextPage(_currentPage, _pageSize);
      emit(state.copyWith(
        isLoading: false,
        shops: List.from(state.shops)..addAll(newShops),
        hasReachedMax: newShops.isEmpty,
      ));
      if (newShops.isNotEmpty) _currentPage++;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading next page: $e',
      ));
    }
  }

  void resetPagination() {
    _currentPage = 0;
    emit(state.copyWith(shops: [], hasReachedMax: false));
  }
}
