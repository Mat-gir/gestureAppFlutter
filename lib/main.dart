import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shake Dice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3EA6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DiceScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────

class DiceResult {
  final List<int> values;
  final DateTime time;

  DiceResult(this.values) : time = DateTime.now();

  int get total => values.fold(0, (a, b) => a + b);
}

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen>
    with SingleTickerProviderStateMixin {
  // Stato dado
  int _numDice = 2;
  List<int> _currentValues = [1, 1];
  List<DiceResult> _history = [];

  // Animazione
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _isRolling = false;

  // GestureDetector shake simulation — usiamo GestureDetector onPanUpdate
  double _shakeAccum = 0;
  static const double _shakeThreshold = 300;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isRolling = false);
      }
    });

    _currentValues = List.generate(_numDice, (_) => 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Lancia i dadi ──────────────────────────
  void _rollDice() {
    if (_isRolling) return;

    HapticFeedback.mediumImpact();

    final rand = Random();
    final newValues = List.generate(_numDice, (_) => rand.nextInt(6) + 1);

    setState(() {
      _isRolling = true;
      _currentValues = newValues;
      _history.insert(0, DiceResult(List.from(newValues)));
      if (_history.length > 10) _history.removeLast();
    });

    _controller.forward(from: 0);
  }

  // ── Cambia numero di dadi ──────────────────
  void _setNumDice(int n) {
    setState(() {
      _numDice = n;
      _currentValues = List.generate(n, (_) => 1);
      _history.clear();
    });
  }

  // ── Rileva gesto shake (swipe veloce) ──────
  void _onPanUpdate(DragUpdateDetails d) {
    _shakeAccum += d.delta.distance;
    if (_shakeAccum >= _shakeThreshold) {
      _shakeAccum = 0;
      _rollDice();
    }
  }

  void _onPanEnd(DragEndDetails _) => _shakeAccum = 0;

  // ─────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0E2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            '🎲 Shake Dice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ── Selettore numero dadi ──────
            _buildDiceSelector(),

            // ── Zona dado principale ───────
            Expanded(
              flex: 3,
              child: _buildDiceZone(),
            ),

            // ── Hint ──────────────────────
            _buildHint(),

            // ── Storico ───────────────────
            Expanded(
              flex: 2,
              child: _buildHistory(),
            ),
          ],
        ),

        // ── FAB: lancia dado ──────────────
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _rollDice,
          backgroundColor: const Color(0xFF9B59B6),
          label: const Text(
            'LANCIA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          icon: const Icon(Icons.casino, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ── Widget: selettore ─────────────────────

  Widget _buildDiceSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Dadi:', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
          for (int i = 1; i <= 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('$i'),
                selected: _numDice == i,
                onSelected: (_) => _setNumDice(i),
                selectedColor: const Color(0xFF9B59B6),
                labelStyle: TextStyle(
                  color: _numDice == i ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: const Color(0xFF2D1B4E),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widget: zona dadi ─────────────────────

  Widget _buildDiceZone() {
    return Center(
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (_, child) {
          final offset = _isRolling
              ? sin(_shakeAnimation.value * pi * 6) * 10
              : 0.0;
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: _currentValues
              .map((v) => _DiceFace(value: v, isRolling: _isRolling))
              .toList(),
        ),
      ),
    );
  }

  // ── Widget: hint ──────────────────────────

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        '✋ Scorri velocemente per lanciare',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  // ── Widget: storico ───────────────────────

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'Nessun lancio ancora...',
          style: TextStyle(color: Colors.white24, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            'Ultimi lanci',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: _history.length,
            itemBuilder: (_, i) {
              final r = _history[i];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4E).withOpacity(i == 0 ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: i == 0
                      ? Border.all(
                          color: const Color(0xFF9B59B6).withOpacity(0.6))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      r.values.map((v) => _diceFace(v)).join('  '),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const Spacer(),
                    Text(
                      'Totale: ${r.total}',
                      style: TextStyle(
                        color: i == 0
                            ? const Color(0xFFCB9FFF)
                            : Colors.white38,
                        fontWeight:
                            i == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Helper: emoji dado ───────────────────

  String _diceFace(int v) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    return faces[(v - 1).clamp(0, 5)];
  }
}

// ─────────────────────────────────────────────
// DiceFace Widget
// ─────────────────────────────────────────────

class _DiceFace extends StatelessWidget {
  final int value;
  final bool isRolling;

  const _DiceFace({required this.value, required this.isRolling});

  @override
  Widget build(BuildContext context) {
    const faces = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];
    final face = faces[(value - 1).clamp(0, 5)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRolling
              ? [const Color(0xFF9B59B6), const Color(0xFF6C3EA6)]
              : [const Color(0xFF3D2266), const Color(0xFF2D1B4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRolling
              ? const Color(0xFFCB9FFF)
              : const Color(0xFF6C3EA6).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B59B6).withOpacity(isRolling ? 0.6 : 0.2),
            blurRadius: isRolling ? 20 : 8,
            spreadRadius: isRolling ? 4 : 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          face,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }
}