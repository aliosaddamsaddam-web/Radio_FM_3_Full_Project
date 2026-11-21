import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() => runApp(const RadioFmApp());

class RadioFmApp extends StatelessWidget {
  const RadioFmApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Radio FM 3',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF36A3FF),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B1020),
          useMaterial3: true,
        ),
        home: const RadioHomePage(),
      );
}

class RadioStation {
  final String name;
  final String url;
  final String country;
  final String codec;

  const RadioStation({
    required this.name,
    required this.url,
    required this.country,
    required this.codec,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) => RadioStation(
        name: (json['name'] ?? 'محطة بدون اسم').toString(),
        url: (json['url_resolved'] ?? json['url'] ?? '').toString(),
        country: (json['country'] ?? '').toString(),
        codec: (json['codec'] ?? '').toString(),
      );
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  final List<RadioStation> _stations = [];
  RadioStation? _current;
  bool _loading = false;
  String? _error;
  bool _isFmMode = true;
  double _frequency = 98.5;

  @override
  void initState() {
    super.initState();
    _loadPopularStations();
  }

  Future<void> _loadPopularStations() async {
    await _searchStations('Yemen');
  }

  Future<void> _searchStations(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.https(
        'de1.api.radio-browser.info',
        '/json/stations/search',
        {
          'name': query.trim().isEmpty ? 'radio' : query.trim(),
          'limit': '30',
          'hidebroken': 'true',
          'order': 'votes',
          'reverse': 'true',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('تعذر تحميل المحطات (${response.statusCode})');
      }
      final decoded = jsonDecode(response.body) as List<dynamic>;
      final found = decoded
          .whereType<Map<String, dynamic>>()
          .map(RadioStation.fromJson)
          .where((s) => s.url.startsWith('http'))
          .toList();
      if (!mounted) return;
      setState(() {
        _stations
          ..clear()
          ..addAll(found);
        if (found.isEmpty) _error = 'لم يتم العثور على محطات. جرّب كلمة بحث أخرى.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر الاتصال. تحقق من الإنترنت ثم أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playStation(RadioStation station) async {
    try {
      setState(() {
        _current = station;
        _error = null;
      });
      await _player.setUrl(station.url);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تشغيل هذه المحطة؛ قد يكون رابط البث متوقفاً.');
    }
  }

  Future<void> _togglePlayback() async {
    if (_isFmMode) {
      _showFmNotice();
      return;
    }
    if (_player.playing) {
      await _player.pause();
    } else if (_current != null) {
      await _player.play();
    } else if (_stations.isNotEmpty) {
      await _playStation(_stations.first);
    } else {
      setState(() => _error = 'ابحث عن محطة أولاً.');
    }
    if (mounted) setState(() {});
  }

  void _showFmNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استقبال FM الحقيقي'),
        content: const Text(
          'وضع FM الحقيقي يحتاج إلى مستقبل FM مدعوم في نسخة الهاتف وإلى واجهة نظام تسمح للتطبيق بالتحكم به. هذه النسخة لا تستطيع تشغيل موجات FM بعد؛ منزلق التردد تجريبي فقط. توصيل السماعة وحده لا يضمن وجود مستقبل FM.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _player.playing;
    return Scaffold(
      appBar: AppBar(
        title: const Text('RADIO FM 3', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF111A2E),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.radio_rounded, size: 62, color: Color(0xFF45B5FF)),
            const Text('راديو اليمن والعالم',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('FM بدون إنترنت'), icon: Icon(Icons.waves)),
                  ButtonSegment(value: false, label: Text('راديو الإنترنت'), icon: Icon(Icons.wifi)),
                ],
                selected: {_isFmMode},
                onSelectionChanged: (s) => setState(() => _isFmMode = s.first),
              ),
            ),
            if (_isFmMode) ...[
              const Text('التردد المختار', style: TextStyle(color: Colors.white70)),
              Text('${_frequency.toStringAsFixed(1)} MHz',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFF45B5FF))),
              Slider(
                min: 87.5,
                max: 108,
                value: _frequency,
                onChanged: (v) => setState(() => _frequency = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setState(() => _frequency = (_frequency - .1).clamp(87.5, 108)),
                      icon: const Icon(Icons.remove_circle_outline), iconSize: 32),
                  IconButton(onPressed: _showFmNotice,
                      icon: const Icon(Icons.play_circle_fill), iconSize: 42, color: Colors.lightBlueAccent),
                  IconButton(onPressed: () => setState(() => _frequency = (_frequency + .1).clamp(87.5, 108)),
                      icon: const Icon(Icons.add_circle_outline), iconSize: 32),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'التردد هنا تجريبي حالياً؛ تشغيل FM بلا إنترنت يتطلب دعماً خاصاً من عتاد الهاتف والنظام.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'ابحث عن محطة أو بلد (Yemen)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: _searchStations,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _searchStations(_searchController.text),
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
              ),
              if (_current != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('المحطة الحالية: ${_current!.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: _togglePlayback,
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    iconSize: 30,
                  ),
                  const SizedBox(width: 12),
                  const Text('البث عبر الإنترنت'),
                ],
              ),
              if (_loading) const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orangeAccent)),
                ),
              Expanded(
                child: _stations.isEmpty
                    ? const Center(child: Text('ابحث عن محطة إذاعية للبدء'))
                    : ListView.builder(
                        itemCount: _stations.length,
                        itemBuilder: (context, index) {
                          final station = _stations[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.radio)),
                            title: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text([station.country, station.codec]
                                .where((v) => v.isNotEmpty).join(' • ')),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => _playStation(station),
                            ),
                            onTap: () => _playStation(station),
                          );
                        },
                      ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.headphones, color: Colors.lightGreenAccent),
                  SizedBox(width: 8),
                  Text('السماعة السلكية: هوائي محتمل للأجهزة المدعومة',
                      style: TextStyle(fontSize: 11, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}