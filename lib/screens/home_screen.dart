import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../widgets/history_card.dart';
import '../services/scan_service.dart';
import 'scan_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  List<ScanResult> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final items = await ScanService.getHistory();

      setState(() {
        _history = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text("Ошибка истории:\n$_error")),
      );
    }

    if (_history.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            "История пуста.\nСделай первый скан.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final item = _history[index];

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ScanDetailsScreen(
                      result: item,
                      loadFromBackend: true, // ВАЖНО: подтягиваем полный текст
                    ),
                  ),
                );
              },
              child: HistoryCard(result: item),
            );
          },
        ),
      ),
    );
  }
}
