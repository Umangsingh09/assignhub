import 'package:dio/dio.dart';

class SupabaseStorageClient {
  final Dio _dio = Dio();
  
  static const _supabaseUrl = 'https://nlmofhlhbsnqftoiyoqh.supabase.co';
  static const _anonKey = 'sb_publishable_HhdGVMuA7geSFRAFD8UEwg_F8x52S7A';

  Future<String> uploadFile({
    required String bucketName,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    // Generate a unique safe filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomHex = (DateTime.now().microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
    final uniqueFileName = '${timestamp}_${randomHex}_$safeName';

    final uploadUrl = '$_supabaseUrl/storage/v1/object/$bucketName/$uniqueFileName';

    final response = await _dio.post(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'ApiKey': _anonKey,
          'Content-Type': mimeType,
        },
      ),
    );

    if (response.statusCode == 200) {
      // Construct and return public URL
      return '$_supabaseUrl/storage/v1/object/public/$bucketName/$uniqueFileName';
    } else {
      throw Exception('Failed to upload to Supabase: ${response.statusCode} - ${response.data}');
    }
  }
}
