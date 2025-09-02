import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://barkod.derinwifi.com/api';
const apiKey  = '12567894389';

Future<List<dynamic>> fetchToptancilar({String q = '', int page = 1, int limit = 50}) async {
  final uri = Uri.parse('$baseUrl/toptancilar.php')
      .replace(queryParameters: {
        'q': q,
        'page': '$page',
        'limit': '$limit',
        'key': apiKey, // basit auth
      });
  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('Liste hata: ${res.body}');
  final json = jsonDecode(res.body);
  return (json['items'] as List?) ?? [];
}

Future<Map<String, dynamic>> fetchToptanciDetay(int id) async {
  final uri = Uri.parse('$baseUrl/toptanci.php')
      .replace(queryParameters: {'id':'$id','key':apiKey});
  final res = await http.get(uri);
  if (res.statusCode != 200) throw Exception('Detay hata: ${res.body}');
  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<bool> createHareket({
  required int toptanciId,
  required String tarih,    // YYYY-MM-DD
  required String tur,      // Alış | Ödeme | İade
  required String tutar,    // "1234,50" veya "1234.50"
  String aciklama = '',
}) async {
  final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/hareket_create.php'));
  req.fields['key'] = apiKey;
  req.fields['toptanci_id'] = '$toptanciId';
  req.fields['tarih'] = tarih;
  req.fields['tur'] = tur;
  req.fields['tutar'] = tutar;
  req.fields['aciklama'] = aciklama;
  final res = await req.send();
  final body = await res.stream.bytesToString();
  if (res.statusCode == 201 || res.statusCode == 200) return true;
  throw Exception('Hareket ekleme hata: $body');
}
