import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';

void main() {
  Intl.defaultLocale = 'tr_TR';
  runApp(const DerinApp());
}

class DerinApp extends StatelessWidget {
  const DerinApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Derin Barkod',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const ToptanciListPage(),
    );
  }
}

class ToptanciListPage extends StatefulWidget {
  const ToptanciListPage({super.key});
  @override
  State<ToptanciListPage> createState() => _ToptanciListPageState();
}

class _ToptanciListPageState extends State<ToptanciListPage> {
  final _controller = TextEditingController();
  List<dynamic> items = [];
  bool loading = true;

  Future<void> _load([String q = '']) async {
    setState(() => loading = true);
    try { items = await fetchToptancilar(q: q); } finally { setState(() => loading = false); }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toptancılar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ara: ad / telefon',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _load(_controller.text.trim()),
                ),
              ),
              onSubmitted: (v) => _load(v.trim()),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(_controller.text.trim()),
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final it = items[i] as Map<String, dynamic>;
                        final net = (it['net'] ?? 0).toDouble();
                        final lastTx = (it['last_tx'] ?? '') as String;
                        return ListTile(
                          title: Text(it['ad'] ?? ''),
                          subtitle: Text('Tel: ${it['telefon'] ?? ''} • Son: $lastTx'),
                          trailing: Text(
                            _tl(net),
                            style: TextStyle(
                              color: net > 0 ? Colors.red : (net < 0 ? Colors.blue : Colors.grey[700]),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ToptanciDetayPage(id: it['id']))),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _tl(double v) {
    final fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return fmt.format(v);
  }
}

class ToptanciDetayPage extends StatefulWidget {
  final int id;
  const ToptanciDetayPage({super.key, required this.id});
  @override
  State<ToptanciDetayPage> createState() => _ToptanciDetayPageState();
}

class _ToptanciDetayPageState extends State<ToptanciDetayPage> {
  Map<String, dynamic>? data;
  bool loading = true;

  Future<void> _load() async {
    setState(() => loading = true);
    try { data = await fetchToptanciDetay(widget.id); } finally { setState(() => loading = false); }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Scaffold(
      appBar: AppBar(title: Text(d?['ad'] ?? 'Detay')),
      floatingActionButton: d == null ? null : FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => HareketEklePage(toptanciId: widget.id)));
          if (ok == true && context.mounted) _load();
        },
        label: const Text('Hareket Ekle'),
        icon: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text('Bulunamadı'))
              : Column(
                  children: [
                    ListTile(
                      title: Text(d['ad'] ?? ''),
                      subtitle: Text('Tel: ${d['telefon'] ?? ''}'),
                      trailing: Text(
                        _tl((d['net'] ?? 0).toDouble()),
                        style: TextStyle(
                          color: (d['net'] ?? 0) > 0 ? Colors.red : ((d['net'] ?? 0) < 0 ? Colors.blue : Colors.grey[700]),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Align(alignment: Alignment.centerLeft, child: Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: (d['hareketler'] as List).length,
                        itemBuilder: (_, i) {
                          final h = d['hareketler'][i] as Map<String, dynamic>;
                          final v = (h['tutar'] ?? 0).toDouble();
                          return ListTile(
                            title: Text('${h['tarih']} • ${h['tur']}'),
                            subtitle: Text(h['aciklama'] ?? ''),
                            trailing: Text(_tl(v), style: const TextStyle(fontWeight: FontWeight.w700)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _tl(double v) => NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(v);
}

class HareketEklePage extends StatefulWidget {
  final int toptanciId;
  const HareketEklePage({super.key, required this.toptanciId});
  @override
  State<HareketEklePage> createState() => _HareketEklePageState();
}

class _HareketEklePageState extends State<HareketEklePage> {
  final formKey = GlobalKey<FormState>();
  String tur = 'Alış';
  final tutarCtrl = TextEditingController();
  DateTime tarih = DateTime.now();
  final aciklamaCtrl = TextEditingController();
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hareket Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              DropdownButtonFormField(
                value: tur,
                items: const ['Alış','Ödeme','İade'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(()=> tur = v!),
                decoration: const InputDecoration(labelText: 'Tür'),
              ),
              TextFormField(
                controller: tutarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Tutar (₺)'),
                validator: (v)=> (v==null || v.trim().isEmpty) ? 'Tutar gir' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tarih'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(tarih)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    initialDate: tarih,
                  );
                  if (picked != null) setState(()=> tarih = picked);
                },
              ),
              TextFormField(
                controller: aciklamaCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(()=> saving = true);
                  try{
                    final ok = await createHareket(
                      toptanciId: widget.toptanciId,
                      tarih: DateFormat('yyyy-MM-dd').format(tarih),
                      tur: tur,
                      tutar: tutarCtrl.text.trim(),
                      aciklama: aciklamaCtrl.text.trim(),
                    );
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedildi')));
                      Navigator.pop(context, true);
                    }
                  } catch(e){
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  } finally { if (mounted) setState(()=> saving = false); }
                },
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
