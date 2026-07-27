import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const BarbellApp());
}

// Логика расчета дисков
class DiscResult {
  final String resultString;
  final List<double> discs; // диски для одной стороны (от штанги наружу)

  const DiscResult({required this.resultString, required this.discs});
}

DiscResult calculateDiscs(double totalWeight) {
  const double barbellWeight = 20.0;
  const double lockWeight = 2.5;
  final List<double> discWeights = [25, 20, 15, 10, 5, 2.5, 1.25, 1, 0.5];

  final double weightOnEachSide =
      (totalWeight - barbellWeight - 2 * lockWeight) / 2;

  if (weightOnEachSide < 0) {
    return const DiscResult(
      resultString:
          'Слишком маленький вес.\nМинимум: гриф (20) + 2 замка (5) = 25 кг.',
      discs: [],
    );
  }

  List<double> greedyFill(double target) {
    final List<double> combo = [];
    double remaining = target;

    for (int i = 0; i < 4 && i < discWeights.length; i++) {
      final double disc = discWeights[i];
      while (remaining >= disc - 0.001) {
        combo.add(disc);
        remaining = double.parse((remaining - disc).toStringAsFixed(3));
      }
    }
    return combo;
  }

  List<List<double>> findCombinations(double target, int startIndex) {
    final List<List<double>> combinations = [];

    void backtrack(List<double> current, double remaining, int index) {
      if (remaining < 0.001 && remaining > -0.001) {
        combinations.add(List.from(current));
        return;
      }
      if (remaining < 0) return;

      for (int i = index; i < discWeights.length; i++) {
        final double disc = discWeights[i];
        current.add(disc);
        backtrack(
          current,
          double.parse((remaining - disc).toStringAsFixed(3)),
          i,
        );
        current.removeLast();
      }
    }

    backtrack([], target, startIndex);
    return combinations;
  }

  final List<double> combination = greedyFill(weightOnEachSide);

  final double usedWeight = combination.fold(0.0, (a, b) => a + b);
  final double remaining =
      double.parse((weightOnEachSide - usedWeight).toStringAsFixed(3));

  if (remaining > 0.001) {
    final additional = findCombinations(remaining, 4);
    if (additional.isEmpty) {
      return const DiscResult(
        resultString: 'Невозможно набрать нужный вес доступными дисками.',
        discs: [],
      );
    }
    combination.addAll(additional[0]);
  }

  final String leftStr = combination.reversed.map(_formatWeight).join(' ');
  final String rightStr = combination.map(_formatWeight).join(' ');

  final double totalSum =
      2 * (combination.fold(0.0, (a, b) => a + b) + lockWeight) + barbellWeight;
  final int totalInt = totalSum.round();

  final String result =
      '${_formatWeight(lockWeight)} = $leftStr = ${_formatWeight(barbellWeight)} = $rightStr = ${_formatWeight(lockWeight)}    [$totalInt кг]';

  return DiscResult(resultString: result, discs: combination);
}

String _formatWeight(double w) {
  if (w == w.roundToDouble()) {
    return w.toInt().toString();
  }
  return w
      .toString()
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

// Цвета дисков
Color discColor(double weight) {
  if (weight == 25) return const Color(0xFFE53935);
  if (weight == 20) return const Color(0xFF1E88E5);
  if (weight == 15) return const Color(0xFFFFEB3B);
  if (weight == 10) return const Color(0xFF43A047);
  if (weight == 5) return const Color(0xFFFFFFFF);
  if (weight == 2.5) return const Color(0xFF212121);
  if (weight == 1.25) return const Color(0xFFBDBDBD);
  if (weight == 1) return const Color(0xFFBDBDBD);
  if (weight == 0.5) return const Color(0xFFBDBDBD);
  return Colors.grey;
}

// Размеры дисков
double discHeight(double weight) {
  if (weight == 25) return 200.0;
  if (weight == 20) return 185.0;
  if (weight == 15) return 165.0;
  if (weight == 10) return 145.0;
  if (weight == 5) return 120.0;
  if (weight == 2.5) return 100.0;
  if (weight == 1.25) return 85.0;
  if (weight == 1) return 70.0;
  if (weight == 0.5) return 55.0;
  return 80.0;
}

double discWidth(double weight) {
  if (weight >= 20) return 28.0;
  if (weight >= 10) return 24.0;
  if (weight >= 5) return 20.0;
  return 16.0;
}

class DiscWidget extends StatelessWidget {
  final double weight;
  const DiscWidget({super.key, required this.weight});

  @override
  Widget build(BuildContext context) {
    final Color color = discColor(weight);
    final double h = discHeight(weight);
    final double w = discWidth(weight);
    final String label = _formatWeight(weight);
    final bool isDark = color.computeLuminance() < 0.3 || color == Colors.black;

    return Container(
      width: w,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black54, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class LockWidget extends StatelessWidget {
  const LockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: const Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            '2.5',
            style: TextStyle(fontSize: 7, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class BarbellBar extends StatelessWidget {
  const BarbellBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFFB0BEC5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              '20 кг',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BarbellApp extends StatelessWidget {
  const BarbellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор дисков штанги',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const BarbellCalculatorPage(),
    );
  }
}

class BarbellCalculatorPage extends StatefulWidget {
  const BarbellCalculatorPage({super.key});

  @override
  State<BarbellCalculatorPage> createState() => _BarbellCalculatorPageState();
}

class _BarbellCalculatorPageState extends State<BarbellCalculatorPage> {
  final TextEditingController _controller = TextEditingController();
  DiscResult? _result;
  String? _error;

  void _calculate() {
    final text = _controller.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(text);

    if (weight == null) {
      setState(() {
        _error = 'Введите числовое значение веса в кг';
        _result = null;
      });
      return;
    }

    final res = calculateDiscs(weight);
    setState(() {
      _error = null;
      _result = res;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Калькулятор дисков штанги',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: const Color(0xFF16213E),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Введите вес на штанге (кг):',
                            style: TextStyle(
                              color: Color(0xFFE94560),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF0F3460),
                              hintText: 'Например: 100',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              suffixText: 'кг',
                              suffixStyle: const TextStyle(
                                color: Colors.white54,
                                fontSize: 18,
                              ),
                            ),
                            onSubmitted: (_) => _calculate(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE94560),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'РАССЧИТАТЬ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_result == null)
                      SizedBox(
                        height: 320,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 80,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Введите вес и нажмите\n«РАССЧИТАТЬ»',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_result!.discs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _result!.resultString,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 280,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Center(
                                child: _BarbellVisual(discs: _result!.discs),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFF0F3460),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                _result!.resultString,
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 16,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          _DiscLegend(discs: _result!.discs),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarbellVisual extends StatelessWidget {
  final List<double> discs;

  const _BarbellVisual({required this.discs});

  @override
  Widget build(BuildContext context) {
    final leftDiscs = discs.reversed.toList();
    final rightDiscs = List<double>.from(discs);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _BarbellHandle(side: 'left'),
        const LockWidget(),
        ...leftDiscs.map((d) => DiscWidget(weight: d)),
        const BarbellBar(),
        ...rightDiscs.map((d) => DiscWidget(weight: d)),
        const LockWidget(),
        const _BarbellHandle(side: 'right'),
      ],
    );
  }
}

class _BarbellHandle extends StatelessWidget {
  final String side;
  const _BarbellHandle({required this.side});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 16,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFFB0BEC5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.horizontal(
          left: side == 'left' ? const Radius.circular(8) : Radius.zero,
          right: side == 'right' ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}

class _DiscLegend extends StatelessWidget {
  final List<double> discs;
  const _DiscLegend({required this.discs});

  @override
  Widget build(BuildContext context) {
    final Map<double, int> counts = {};
    for (final d in discs) {
      counts[d] = (counts[d] ?? 0) + 1;
    }

    final sorted = counts.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: sorted.map((w) {
          final count = counts[w]!;
          final color = discColor(w);
          final isDark = color.computeLuminance() < 0.3;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black26),
            ),
            child: Text(
              '${_formatWeight(w)} кг × ${count * 2}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}