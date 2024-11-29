// data/repositories/image_repository.dart
import "supabase_client.dart";

class ImageRepository {
  final String bucketName;

  ImageRepository(this.bucketName);

  Future<String?> fetchImageUrl(String imageName) async {

      final response = SupabaseConfig.client.storage.from(bucketName).getPublicUrl(imageName);

    return response;
  }
}