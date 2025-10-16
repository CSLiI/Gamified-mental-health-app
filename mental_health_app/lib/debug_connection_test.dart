import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DebugConnectionTest extends StatefulWidget {
  const DebugConnectionTest({super.key});

  @override
  State<DebugConnectionTest> createState() => _DebugConnectionTestState();
}

class _DebugConnectionTestState extends State<DebugConnectionTest> {
  final List<String> _logs = [];
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _runTests() async {
    setState(() {
      _testing = true;
      _logs.clear();
    });

    _addLog('🔍 Starting connection diagnostics...');
    _addLog('');

    // Test different URLs
    final urlsToTest = [
      'http://10.0.2.2:8000',           // Android Emulator
      'http://localhost:8000',          // iOS Simulator
      'http://127.0.0.1:8000',          // Localhost

      // ⚠️ ADD YOUR LAPTOP'S IP HERE:
      'http://10.200.235.213:8000',       // Common hotspot IP
      // 'http://192.168.1.XXX:8000',   // Replace XXX with your IP
      // 'http://10.0.0.XXX:8000',      // Alternative
    ];

    for (final url in urlsToTest) {
      await _testUrl(url);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() {
      _testing = false;
    });

    _addLog('');
    _addLog('✅ Diagnostics complete!');
  }

  Future<void> _testUrl(String url) async {
    _addLog('');
    _addLog('Testing: $url');

    try {
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      _addLog('  → Attempting connection...');
      _addLog('  → Full URL: $url/health');

      final stopwatch = Stopwatch()..start();
      final response = await dio.get('/health');
      stopwatch.stop();

      if (response.statusCode == 200) {
        _addLog('  ✅ SUCCESS! This URL works!');
        _addLog('  Response time: ${stopwatch.elapsedMilliseconds}ms');
        _addLog('  Status: ${response.statusCode}');
        _addLog('  Data: ${response.data}');
        _addLog('  ');
        _addLog('  🎯 USE THIS URL IN api_constants.dart:');
        _addLog('  static const String baseUrl = \'$url\';');
      } else {
        _addLog('  ⚠️ Unexpected status: ${response.statusCode}');
      }

    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        _addLog('  ❌ Timeout - Cannot reach server after 10s');
        _addLog('  Possible causes:');
        _addLog('     • Backend not running');
        _addLog('     • Wrong IP address');
        _addLog('     • Firewall blocking connection');
      } else if (e.type == DioExceptionType.connectionError) {
        _addLog('  ❌ Connection Error - Server not reachable');
        _addLog('  Error: ${e.message}');
        _addLog('  Possible causes:');
        _addLog('     • Backend not listening on 0.0.0.0');
        _addLog('     • Different port number');
        _addLog('     • Phone not on same network');
      } else if (e.type == DioExceptionType.badResponse) {
        _addLog('  ❌ Bad Response: ${e.response?.statusCode}');
        _addLog('  Data: ${e.response?.data}');
      } else {
        _addLog('  ❌ Error: ${e.type}');
        _addLog('  Message: ${e.message}');
      }
    } catch (e) {
      _addLog('  ❌ Unknown error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testing ? null : _runTests,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_testing)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: log.contains('✅')
                          ? Colors.green
                          : log.contains('❌')
                              ? Colors.red
                              : log.contains('⚠️')
                                  ? Colors.orange
                                  : Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Make sure backend is running:\n'
                  '   python main.py\n\n'
                  '2. One of the URLs above should show ✅\n\n'
                  '3. Use that URL in api_constants.dart',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}