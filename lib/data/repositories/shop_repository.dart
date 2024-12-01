import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_model.dart';

class ShopRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ShopModel>> fetchShopsByServiceType(String serviceType) async {
    final response = await _client
        .from('shops') // Replace 'shops' with your table name in Supabase
        .select()
        .eq('servicetype', serviceType);

    // The response itself is the data; no need to access `.data` or `.error`.
    return (response as List<dynamic>)
        .map((shop) => ShopModel.fromJson(shop as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShopModel>> fetchNextPage(int page, int pageSize) async {
    final response = await _client
        .from('shops')
        .select()
        .range(page * pageSize, (page + 1) * pageSize - 1);

    // The response itself is the data; no need to access `.data` or `.error`.
    return (response as List<dynamic>)
        .map((shop) => ShopModel.fromJson(shop as Map<String, dynamic>))
        .toList();
  }
}
