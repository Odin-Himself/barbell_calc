import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  final double remaining = double.parse(
    (weightOnEachSide - usedWeight).toStringAsFixed(3),
  );

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
  if (weight == 25) return 300.0;
  if (weight == 20) return 300.0;
  if (weight == 15) return 270.0;
  if (weight == 10) return 220.0;
  if (weight == 5) return 160.0;
  if (weight == 2.5) return 140.0;
  if (weight == 1.25) return 100.0;
  if (weight == 1) return 100.0;
  if (weight == 0.5) return 80.0;
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
  final int? topIndex; // номер сверху (только если нужен)
  const DiscWidget({super.key, required this.weight, this.topIndex});

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
      child: Stack(
        children: [
          // Номер сверху (например 1,2,3 для красных 25 кг)
          if (topIndex != null)
            Positioned(
              left: 0,
              right: 0,
              top: 5, // на 5 px ниже верхней кромки
              child: Center(
                child: Text(
                  '$topIndex',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),

          // Вес по центру
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // KG снизу
          Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: Center(
              child: Text(
                'KG',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LockWidget extends StatelessWidget {
  const LockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const double handleCoreWidth = 22; // меняете только длину ручки
    const double handleShiftX = 4; // общий сдвиг ручки вправо/влево

    const double lockWidth = 28;
    const double lockHeight = 60;

    const double capWidth = 6;
    const double capHeight = 5;
    const double handleHeight = 5;

    final double handleGroupWidth = capWidth + handleCoreWidth + capWidth;
    final double handleLeft = (lockWidth - handleGroupWidth) / 2 + handleShiftX;

    return Container(
      width: lockWidth,
      height: lockHeight,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Text(
              '2.5',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 5,
            child: Center(
              child: Text(
                'KG',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            top: -12,
            left: handleLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: capWidth,
                  height: capHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(1.5),
                    border: Border.all(color: Colors.black38, width: 0.7),
                  ),
                ),
                Container(
                  width: handleCoreWidth,
                  height: handleHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9E9E9E),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.black45, width: 0.8),
                  ),
                ),
                Container(
                  width: capWidth,
                  height: capHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(1.5),
                    border: Border.all(color: Colors.black38, width: 0.7),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 7,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF9E9E9E),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.black45, width: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarbellBar extends StatelessWidget {
  const BarbellBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFFB0BEC5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        // Убрали borderRadius: углы теперь прямые
        border: Border.all(
          color: Colors.black54,
          width: 1,
        ), // обводка как у дисков
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
  bool _includeLocks = true; // положение переключателя "Учитывать вес замков"

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
      backgroundColor: Colors.white,
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
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: Text(
                              'Введите вес на штанге, кг',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: 280,
                              child: TextField(
                                controller: _controller,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: false,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                                ],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF1F3F5),
                                  hintText: 'Например: 100',
                                  hintStyle: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53935),
                                      width: 2, // Толщина обводки поля ввода
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53935),
                                      width: 2, // Толщина обводки поля ввода
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  suffixText: 'кг',
                                  suffixStyle: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                  ),
                                ),
                                onSubmitted: (_) => _calculate(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: 280,
                              child: ElevatedButton(
                                onPressed: _calculate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const StadiumBorder(),
                                  elevation: 2,
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
                          ),
                          const SizedBox(height: 12), // тот же отступ, что между полем и кнопкой
Center(
  child: SizedBox(
    width: 280, // та же ширина, что у поля и кнопки
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Учитывать вес замков 2,5 кг',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(
          value: _includeLocks,
          activeColor: Colors.white, // цвет бегунка во включенном состоянии
          activeTrackColor: const Color(0xFFE53935), // дорожка как диск 25 кг
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFBDBDBD),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (value) {
            setState(() {
              _includeLocks = value;
            });
          },
        ),
      ],
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
                                color: Colors.black.withOpacity(0.15),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Введите вес и нажмите\n«РАССЧИТАТЬ»',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.3),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Center(
                                child: _BarbellVisual(discs: _result!.discs),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Проверочная строка',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    _result!.resultString,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
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
  final List<double> discs; // диски одной стороны (от центра к краю)

  const _BarbellVisual({required this.discs});

  @override
  Widget build(BuildContext context) {
    final oneSideDiscs = List<double>.from(discs);

    final int redCount = oneSideDiscs.where((d) => d == 25).length;
    int redIndex = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Гриф (нижний слой) + бобышка (верхний слой) с нахлестом.
        SizedBox(
          width: 103, // 80 + 24 - 1
          height: 76,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: const [
              Positioned(left: 0, child: BarbellBar()),
              Positioned(
                left: 79, // заход бобышки на гриф на 1 px
                child: _BarbellBobyshka(),
              ),
            ],
          ),
        ),

        // Нижний слой: втулка (сдвинута влево под бобышку).
        // Верхний слой: диски + замок.
        Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(-1, 0), // втулка уходит под бобышку на 1 px
              child: const _BarbellSleeve(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...oneSideDiscs.map((d) {
                  int? idx;
                  if (d == 25 && redCount > 1) {
                    redIndex += 1;
                    idx = redIndex;
                  }
                  return DiscWidget(weight: d, topIndex: idx);
                }),
                const LockWidget(),
              ],
            ),
          ],
        ),
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

class _BarbellSleeve extends StatelessWidget {
  const _BarbellSleeve();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFFB0BEC5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.horizontal(
          left: Radius.zero,
          right: Radius.circular(6),
        ),
        border: Border.all(color: Colors.black45, width: 1),
      ),
    );
  }
}

class _BarbellBobyshka extends StatelessWidget {
  const _BarbellBobyshka();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, // уже замка (у замка сейчас 28)
      height: 76, // выше грифа/втулки, но ниже замка
      margin: const EdgeInsets.only(right: 1),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB0BEC5), Color(0xFF546E7A), Color(0xFFB0BEC5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black45, width: 1),
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
