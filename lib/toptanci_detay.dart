import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api.dart';

class ToptanciDetayPage extends StatefulWidget {
  final int id;
  final String ad;
  ToptanciDetayPage({required this.id, required this.ad});

  @override
  State<ToptanciDetayPage> createState() => _ToptanciDetayPageState();
}

class _ToptanciDetayPageState extends State<ToptanciDetayPage> {
  Map<String, dynamic>? detay;
  bool _loading = true;
  final _tutarCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  String _tur = "Alış";
  File? _pickedFile;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  void _yukle() async {
    final d = await ApiService.getToptanciDetail(widget.id);
    setState(() {
      detay = d;
      _loading = false;
    });
  }

  Future<void> _hareketEkle() async {
    if (_tutarCtrl.text.isEmpty) return;
    final tutar = double.tryParse(_tutarCtrl.text) ?? 0.0;

    final ok = await ApiService.addHareket(
      toptanciId: widget.id,
      tur: _tur,
      tutar: tutar,
      aciklama: _aciklamaCtrl.text,
      imageFile: _pickedFile,
    );

    if (ok) {
      Navigator.pop(context);
      _yukle();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hareket eklenemedi")),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedFile = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ad)),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  title: Text("Net Bakiye"),
                  subtitle: Text("${detay?['net']} ₺"),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: detay?['hareketler']?.length ?? 0,
                    itemBuilder: (c, i) {
                      final h = detay!['hareketler'][i];
                      return ListTile(
                        title: Text("${h['tur']} - ${h['tutar']} ₺"),
                        subtitle: Text(h['aciklama'] ?? ""),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _tutarCtrl,
                        decoration: InputDecoration(labelText: "Tutar"),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _aciklamaCtrl,
                        decoration: InputDecoration(labelText: "Açıklama"),
                      ),
                      DropdownButton<String>(
                        value: _tur,
                        items: ["Alış", "Ödeme", "İade"]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _tur = v!),
                      ),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text("Resim Ekle"),
                      ),
                      if (_pickedFile != null)
                        Image.file(_pickedFile!, height: 80),
                      ElevatedButton(
                        onPressed: _hareketEkle,
                        child: Text("Hareket Kaydet"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
