import 'dart:convert';
import 'dart:io';
import '../../features/rule_book/model/legal_document.dart';

class NepalLawApiResponse {
  final List<LegalDocument> documents;
  final String? error;

  const NepalLawApiResponse({required this.documents, this.error});
}

class NepalLawApi {
  static const _baseUrl = 'https://nepal-law-mcp.vercel.app/mcp';
  static const _timeout = Duration(seconds: 15);

  static final Set<String> _defaultCategories = {
    'Constitution', 'Civil Law', 'Criminal Law', 'Local Governance',
    'Property Law', 'Corporate Law', 'Public Administration',
    'Human Rights', 'Technology Law', 'Environment Law', 'Education Law',
  };

  static Future<NepalLawApiResponse> fetchDocuments({String query = ''}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = _timeout;
      try {
        final request = await client.postUrl(Uri.parse(_baseUrl));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'query': query}));
        final response = await request.close();
        if (response.statusCode != 200) {
          return NepalLawApiResponse(
            documents: [],
            error: 'Server returned ${response.statusCode}',
          );
        }
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        return _parseResponse(data);
      } finally {
        client.close();
      }
    } on SocketException {
      return const NepalLawApiResponse(
        documents: [],
        error: 'No internet connection',
      );
    } on HttpException {
      return const NepalLawApiResponse(
        documents: [],
        error: 'Server unavailable',
      );
    } on FormatException {
      return const NepalLawApiResponse(
        documents: [],
        error: 'Invalid response format',
      );
    } catch (e) {
      return NepalLawApiResponse(
        documents: [],
        error: 'Unexpected error: $e',
      );
    }
  }

  static Future<NepalLawApiResponse> fetchByCategory(String category) async {
    return fetchDocuments(query: category);
  }

  static Future<NepalLawApiResponse> search(String searchTerm) async {
    return fetchDocuments(query: searchTerm);
  }

  static Future<NepalLawApiResponse> fetchAll() async {
    final results = <LegalDocument>[];
    String? lastError;
    for (final category in _defaultCategories) {
      final response = await fetchByCategory(category);
      if (response.error != null) {
        lastError = response.error;
      } else if (response.documents.isNotEmpty) {
        results.addAll(response.documents);
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (results.isEmpty && lastError != null) {
      return NepalLawApiResponse(documents: [], error: lastError);
    }
    return NepalLawApiResponse(documents: results);
  }

  static Future<bool> checkConnectivity() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.postUrl(Uri.parse(_baseUrl));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'query': 'test'}));
        final response = await request.close();
        return response.statusCode == 200;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }

  static NepalLawApiResponse _parseResponse(dynamic data) {
    try {
      if (data is List) {
        final docs = data.map((item) => _parseDocument(item)).toList();
        return NepalLawApiResponse(documents: docs);
      }
      if (data is Map<String, dynamic>) {
        if (data.containsKey('documents') || data.containsKey('results')) {
          final list = data['documents'] as List? ?? data['results'] as List? ?? [];
          final docs = list.map((item) => _parseDocument(item)).toList();
          return NepalLawApiResponse(documents: docs);
        }
        final single = _parseDocument(data);
        return NepalLawApiResponse(documents: [single]);
      }
      return const NepalLawApiResponse(documents: []);
    } catch (e) {
      return NepalLawApiResponse(documents: [], error: 'Parse error: $e');
    }
  }

  static LegalDocument _parseDocument(dynamic item) {
    final map = item as Map<String, dynamic>;
    return LegalDocument(
      id: _str(map, 'id') ?? _str(map, '_id') ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titleEn: _str(map, 'titleEn') ?? _str(map, 'title_en') ?? _str(map, 'title') ?? 'Untitled',
      titleNp: _str(map, 'titleNp') ?? _str(map, 'title_np') ?? _str(map, 'titleNepali') ?? '',
      category: _str(map, 'category') ?? _str(map, 'cat') ?? 'General',
      contentEn: _str(map, 'contentEn') ?? _str(map, 'content_en') ?? _str(map, 'content') ?? _str(map, 'body') ?? '',
      contentNp: _str(map, 'contentNp') ?? _str(map, 'content_np') ?? _str(map, 'contentNepali') ?? '',
      keywords: _list(map, 'keywords') ?? _list(map, 'tags') ?? [],
    );
  }

  static String? _str(Map<String, dynamic> map, String key) {
    final v = map[key];
    return v is String ? v : null;
  }

  static List<String>? _list(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is List) return v.whereType<String>().toList();
    return null;
  }
}
