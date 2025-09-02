import 'package:flutter/material.dart';
import 'api.dart';

class YeniToptanciPage extends StatefulWidget {
  @override
  State<YeniToptanciPage> createState() => _YeniToptanciPageState();
}

class _YeniToptanciPageState extends State<YeniToptanciPage> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  bool _loading = false;

  void _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await ApiService.createToptanci(_adCtrl.text, _telCtrl.text);

    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Toptancı eklendi")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ekleme başarısız")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Yeni Toptancı")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _adCtrl,
                decoration: InputDecoration(labelText: "Ad"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Ad gerekli" : null,
              ),
              TextFormField(
                controller: _telCtrl,
                decoration: InputDecoration(labelText: "Telefon"),
              ),
              const SizedBox(height: 20),
              _loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _kaydet,
                      child: Text("Kaydet"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
