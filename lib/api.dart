import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = "https://barkod.derinwifi.com/api";
  static const String apiKey = "12567894389"; // sabit API key

  // --- Toptancılar listesi ---
  static Future<List<dynamic>> getToptancilar() async {
    final res = await http.get(
      Uri.parse("$baseUrl/toptancilar.php?key=$apiKey"),
      headers: {"Accept": "application/json"},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data["items"] ?? [];
    } else {
      throw Exception("Toptancılar alınamadı");
    }
  }

  // --- Yeni toptancı ekle ---
  static Future<bool> createToptanci(String ad, String telefon) async {
    final res = await http.post(
      Uri.parse("$baseUrl/toptanci_ekle.php?key=$apiKey"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"ad": ad, "telefon": telefon}),
    );
    return res.statusCode == 200;
  }

  // --- Toptancı detayını getir ---
  static Future<Map<String, dynamic>> getToptanciDetail(int id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/toptanci_detay.php?id=$id&key=$apiKey"),
      headers: {"Accept": "application/json"},
    );
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception("Detay alınamadı");
    }
  }

  // --- Hareket ekle (opsiyonel resim ile) ---
  static Future<bool> addHareket({
    required int toptanciId,
    required String tur,
    required double tutar,
    required String aciklama,
    File? imageFile,
  }) async {
    final url = Uri.parse("$baseUrl/hareket_ekle.php?key=$apiKey");
    final req = http.MultipartRequest("POST", url);
    req.fields["toptanci_id"] = toptanciId.toString();
    req.fields["tur"] = tur;
    req.fields["tutar"] = tutar.toString();
    req.fields["aciklama"] = aciklama;

    if (imageFile != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "resim",
          imageFile.path,
          contentType: MediaType("image", "jpeg"),
        ),
      );
    }

    final res = await req.send();
    return res.statusCode == 200;
  }
}
