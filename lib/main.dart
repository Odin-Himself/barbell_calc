import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

DiscResult calculateDiscs(double totalWeight, {bool includeLocks = true}) {
  const double barbellWeight = 20.0;
  final double lockWeight = includeLocks ? 2.5 : 0.0;

  final List<double> discWeights = [25, 20, 15, 10, 5, 2.5, 1.25, 1, 0.5];

  final double weightOnEachSide =
      (totalWeight - barbellWeight - 2 * lockWeight) / 2;

  if (weightOnEachSide < 0) {
    return DiscResult(
      resultString: includeLocks
          ? 'Слишком маленький вес.\nМинимум: гриф (20) + 2 замка (5) = 25 кг.'
          : 'Слишком маленький вес.\nМинимум: только гриф = 20 кг.',
      discs: const [],
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

  final String result = includeLocks
      ? '${_formatWeight(lockWeight)} = $leftStr = ${_formatWeight(barbellWeight)} = $rightStr = ${_formatWeight(lockWeight)}    [$totalInt кг]'
      : '$leftStr = ${_formatWeight(barbellWeight)} = $rightStr    [$totalInt кг]';

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
  final int? topIndex;
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
          if (topIndex != null)
            Positioned(
              left: 0,
              right: 0,
              top: 5,
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
    const double handleCoreWidth = 22;
    const double handleShiftX = 4;

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
        border: Border.all(color: Colors.black54, width: 1),
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

enum AppThemeOption { light, matrix, midnight, amber, forest }

class AppPalette {
  final String label;
  final String description;
  final Color background;
  final Color surface;
  final Color appBar;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color outline;
  final Color inputFill;
  final Color tableHeader;
  final Color success;
  final Brightness brightness;

  const AppPalette({
    required this.label,
    required this.description,
    required this.background,
    required this.surface,
    required this.appBar,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.outline,
    required this.inputFill,
    required this.tableHeader,
    required this.success,
    required this.brightness,
  });
}

AppPalette paletteOf(AppThemeOption option) {
  switch (option) {
    case AppThemeOption.light:
      return const AppPalette(
        label: 'Светлая',
        description: 'Классический светлый вид',
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        appBar: Color(0xFF16213E),
        text: Color(0xFF212121),
        textMuted: Color(0xFF616161),
        accent: Color(0xFFE53935),
        onAccent: Color(0xFFFFFFFF),
        outline: Color(0xFFE0E0E0),
        inputFill: Color(0xFFF1F3F5),
        tableHeader: Color(0xFFF5F7FA),
        success: Color(0xFF2E7D32),
        brightness: Brightness.light,
      );
    case AppThemeOption.matrix:
      return const AppPalette(
        label: 'Матрица',
        description: 'Темно-серый фон и зеленый текст',
        background: Color(0xFF1F2328),
        surface: Color(0xFF2A2F35),
        appBar: Color(0xFF171B20),
        text: Color(0xFF39FF14),
        textMuted: Color(0xFF8AFF76),
        accent: Color(0xFF00E676),
        onAccent: Color(0xFF0E1A12),
        outline: Color(0xFF00C853),
        inputFill: Color(0xFF333A42),
        tableHeader: Color(0xFF233128),
        success: Color(0xFF39FF14),
        brightness: Brightness.dark,
      );
    case AppThemeOption.midnight:
      return const AppPalette(
        label: 'Полночь',
        description: 'Темно-синий фон и голубые акценты',
        background: Color(0xFF0F172A),
        surface: Color(0xFF17233A),
        appBar: Color(0xFF0B1222),
        text: Color(0xFFE2ECFF),
        textMuted: Color(0xFFA2B5D8),
        accent: Color(0xFF4FC3F7),
        onAccent: Color(0xFF062033),
        outline: Color(0xFF4D6488),
        inputFill: Color(0xFF233554),
        tableHeader: Color(0xFF21314D),
        success: Color(0xFF81C784),
        brightness: Brightness.dark,
      );
    case AppThemeOption.amber:
      return const AppPalette(
        label: 'Янтарь',
        description: 'Графит и теплые янтарные линии',
        background: Color(0xFF24201A),
        surface: Color(0xFF2F2A22),
        appBar: Color(0xFF1E1A15),
        text: Color(0xFFF6E7CA),
        textMuted: Color(0xFFD9C7A6),
        accent: Color(0xFFFFB74D),
        onAccent: Color(0xFF2A1B08),
        outline: Color(0xFF8A714A),
        inputFill: Color(0xFF3A3329),
        tableHeader: Color(0xFF3B342A),
        success: Color(0xFFA5D6A7),
        brightness: Brightness.dark,
      );
    case AppThemeOption.forest:
      return const AppPalette(
        label: 'Лес',
        description: 'Темно-зеленый фон и мятные акценты',
        background: Color(0xFF16221A),
        surface: Color(0xFF1F2D23),
        appBar: Color(0xFF111B14),
        text: Color(0xFFD8F5E2),
        textMuted: Color(0xFFA5D8B9),
        accent: Color(0xFF6DD39E),
        onAccent: Color(0xFF102218),
        outline: Color(0xFF4F8968),
        inputFill: Color(0xFF2A3A2F),
        tableHeader: Color(0xFF2A3A30),
        success: Color(0xFFA5D6A7),
        brightness: Brightness.dark,
      );
  }
}

class BarbellApp extends StatefulWidget {
  const BarbellApp({super.key});

  @override
  State<BarbellApp> createState() => _BarbellAppState();
}

class _BarbellAppState extends State<BarbellApp> {
  static const String _themeStorageKey = 'barbell_theme_v1';

  AppThemeOption _selectedTheme = AppThemeOption.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_themeStorageKey);
    if (idx == null) return;
    if (idx < 0 || idx >= AppThemeOption.values.length) return;
    if (!mounted) return;

    setState(() {
      _selectedTheme = AppThemeOption.values[idx];
    });
  }

  Future<void> _setTheme(AppThemeOption option) async {
    setState(() {
      _selectedTheme = option;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeStorageKey, option.index);
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteOf(_selectedTheme);

    return MaterialApp(
      title: 'Калькулятор дисков штанги',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        brightness: palette.brightness,
      ),
      home: BarbellCalculatorPage(
        selectedTheme: _selectedTheme,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

class RecordRow {
  String date;
  String exercise;
  String weight;
  String reps;

  RecordRow({
    required this.date,
    required this.exercise,
    required this.weight,
    required this.reps,
  });

  factory RecordRow.empty() {
    return RecordRow(date: '', exercise: '', weight: '', reps: '');
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'exercise': exercise,
        'weight': weight,
        'reps': reps,
      };

  factory RecordRow.fromJson(Map<String, dynamic> json) {
    return RecordRow(
      date: (json['date'] ?? '').toString(),
      exercise: (json['exercise'] ?? '').toString(),
      weight: (json['weight'] ?? '').toString(),
      reps: (json['reps'] ?? '').toString(),
    );
  }
}

class DateDdMmYyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 6) digits = digits.substring(0, 6);

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i != digits.length - 1) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BarbellCalculatorPage extends StatefulWidget {
  final AppThemeOption selectedTheme;
  final ValueChanged<AppThemeOption> onThemeChanged;

  const BarbellCalculatorPage({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<BarbellCalculatorPage> createState() => _BarbellCalculatorPageState();
}

class _BarbellCalculatorPageState extends State<BarbellCalculatorPage> {
  final TextEditingController _controller = TextEditingController();
  DiscResult? _result;
  String? _error;
  bool _includeLocks = true;
  int _activeTab = 0;

  static const String _recordsStorageKey = 'my_records_v1';

  final List<RecordRow> _records = [RecordRow.empty()];

  final RecordRow _firstRowHint = RecordRow(
    date: '16.08.26',
    exercise: 'Присед',
    weight: '140',
    reps: '5',
  );

  bool _recordsLoaded = false;
  String? _recordsMessage;

  AppPalette get _palette => paletteOf(widget.selectedTheme);

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsStorageKey);

    if (raw == null || raw.isEmpty) {
      setState(() {
        _recordsLoaded = true;
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _records
          ..clear()
          ..addAll(
            decoded.map(
              (e) => RecordRow.fromJson(Map<String, dynamic>.from(e)),
            ),
          );
        if (_records.isEmpty) {
          _records.add(RecordRow.empty());
        }
      }
    } catch (_) {
      _records
        ..clear()
        ..add(RecordRow.empty());
    }

    setState(() {
      _recordsLoaded = true;
    });
  }

  Future<void> _saveRecords() async {
    final dateRegExp = RegExp(r'^\d{2}\.\d{2}\.\d{2}$');

    for (int i = 0; i < _records.length; i++) {
      final date = _records[i].date.trim();
      if (date.isNotEmpty && !dateRegExp.hasMatch(date)) {
        setState(() {
          _recordsMessage =
              'Ошибка в строке ${i + 1}: дата только в формате дд.мм.гг';
        });
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_recordsStorageKey, payload);

    setState(() {
      _recordsMessage = 'Данные сохранены';
    });
  }

  void _addRecordRow() {
    setState(() {
      _records.add(RecordRow.empty());
      _recordsMessage = null;
    });
  }

  void _removeRecordRow() {
    if (_records.length <= 1) return;
    setState(() {
      _records.removeLast();
      _recordsMessage = null;
    });
  }

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

    final res = calculateDiscs(weight, includeLocks: _includeLocks);
    setState(() {
      _error = null;
      _result = res;
    });
  }

  void _onIncludeLocksChanged(bool value) {
    setState(() {
      _includeLocks = value;
    });

    final text = _controller.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(text);

    if (weight != null) {
      _calculate();
    }
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final bool isActive = _activeTab == index;

    return SizedBox(
      width: 135,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _palette.accent : _palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _palette.outline, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? _palette.onAccent : _palette.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? _palette.onAccent : _palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationTab() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: _palette.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Введите вес на штанге, кг',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _palette.text,
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
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.,]'),
                              ),
                            ],
                            style: TextStyle(
                              color: _palette.text,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _palette.inputFill,
                              hintText: 'Например: 100',
                              hintStyle: TextStyle(
                                color: _palette.textMuted,
                                fontSize: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: _palette.accent,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: _palette.accent,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              suffixText: 'кг',
                              suffixStyle: TextStyle(
                                color: _palette.textMuted,
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
                              backgroundColor: _palette.accent,
                              foregroundColor: _palette.onAccent,
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
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          width: 280,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Учитывать вес замков\n2,5 кг',
                                  style: TextStyle(
                                    color: _palette.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  const double knobDiameter = 24;
                                  const double trackPadding = 3;
                                  final double trackHeight =
                                      knobDiameter + trackPadding * 2;
                                  final double trackWidth =
                                      knobDiameter * 2.05 + trackPadding * 2;

                                  return GestureDetector(
                                    onTap: () =>
                                        _onIncludeLocksChanged(!_includeLocks),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOut,
                                      width: trackWidth,
                                      height: trackHeight,
                                      padding: const EdgeInsets.all(
                                        trackPadding,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _includeLocks
                                            ? _palette.accent
                                            : _palette.outline,
                                        borderRadius: BorderRadius.circular(
                                          trackHeight / 2,
                                        ),
                                      ),
                                      child: AnimatedAlign(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOut,
                                        alignment: _includeLocks
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: knobDiameter,
                                          height: knobDiameter,
                                          decoration: BoxDecoration(
                                            color: _palette.surface,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
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
                            color: _palette.text.withOpacity(0.18),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Введите вес и нажмите\n«РАССЧИТАТЬ»',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _palette.text.withOpacity(0.35),
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
                            child: _BarbellVisual(
                              discs: _result!.discs,
                              includeLocks: _includeLocks,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Проверочная строка',
                              style: TextStyle(
                                color: _palette.text,
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
                                style: TextStyle(
                                  color: _palette.text,
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
                      _DiscLegend(discs: _result!.discs, palette: _palette),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget _buildRecordsTab() {
    if (!_recordsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget editableCell({
      required String value,
      required String hint,
      required ValueChanged<String> onChanged,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      double width = 90,
    }) {
      const double userInputFontSize =
          12; // Можешь менять вручную: 11, 12, 13, чтобы подобрать кегль

      return SizedBox(
        width: width,
        child: TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: userInputFontSize,
            color: _palette.text,
          ),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _palette.surface,
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: userInputFontSize,
              color: _palette.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _palette.accent, width: 2),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: _palette.accent,
                      size: 30,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Мои рекорды',
                      style: TextStyle(
                        color: _palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.topCenter,
                  child: IntrinsicWidth(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _palette.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              _palette.brightness == Brightness.dark ? 0.25 : 0.08,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: DataTable(
                          columnSpacing: 8,
                          horizontalMargin: 10,
                          headingRowColor: MaterialStateProperty.all(
                            _palette.tableHeader,
                          ),
                          dataRowMinHeight: 54,
                          dataRowMaxHeight: 62,
                          dividerThickness: 1,
                          headingTextStyle: TextStyle(
                            color: _palette.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          dataTextStyle: TextStyle(
                            color: _palette.text,
                            fontSize: 13,
                          ),
                          columns: const [
                            DataColumn(label: Text('№')),
                            DataColumn(label: Text('Дата')),
                            DataColumn(label: Text('Упражнение')),
                            DataColumn(label: Text('Вес, кг')),
                            DataColumn(label: Text('Повт.')),
                          ],
                          rows: List.generate(_records.length, (index) {
                            final row = _records[index];
                            final isFirst = index == 0;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _palette.text,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  editableCell(
                                    value: row.date,
                                    hint: isFirst ? _firstRowHint.date : '',
                                    width: 104,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [DateDdMmYyFormatter()],
                                    onChanged: (v) => row.date = v,
                                  ),
                                ),
                                DataCell(
                                  editableCell(
                                    value: row.exercise,
                                    hint: isFirst ? _firstRowHint.exercise : '',
                                    width: 150,
                                    onChanged: (v) => row.exercise = v,
                                  ),
                                ),
                                DataCell(
                                  editableCell(
                                    value: row.weight,
                                    hint: isFirst ? _firstRowHint.weight : '',
                                    width: 84,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]'),
                                      ),
                                    ],
                                    onChanged: (v) => row.weight = v,
                                  ),
                                ),
                                DataCell(
                                  editableCell(
                                    value: row.reps,
                                    hint: isFirst ? _firstRowHint.reps : '',
                                    width: 72,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (v) => row.reps = v,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addRecordRow,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: _palette.surface,
                          foregroundColor: _palette.text,
                          side: BorderSide(color: _palette.outline),
                          elevation: 1,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          '+',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _removeRecordRow,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: _palette.surface,
                          foregroundColor: _palette.text,
                          side: BorderSide(color: _palette.outline),
                          elevation: 1,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: _saveRecords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _palette.accent,
                        foregroundColor: _palette.onAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_recordsMessage != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _recordsMessage!,
                      style: TextStyle(
                        color: _recordsMessage!.startsWith('Ошибка')
                            ? Colors.redAccent
                            : _palette.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.palette_outlined, color: _palette.accent, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Настройки темы',
                      style: TextStyle(
                        color: _palette.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Выберите цветовое оформление интерфейса:',
                  style: TextStyle(
                    color: _palette.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...AppThemeOption.values.map(_buildThemeOptionTile),
                const SizedBox(height: 8),
                Text(
                  'Цвета дисков, грифа и замков не меняются при смене темы.',
                  style: TextStyle(
                    color: _palette.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(AppThemeOption option) {
    final p = paletteOf(option);
    final bool selected = widget.selectedTheme == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: () => widget.onThemeChanged(option),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? _palette.accent.withOpacity(0.12) : _palette.surface,
          side: BorderSide(
            color: selected ? _palette.accent : _palette.outline,
            width: selected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.accent,
                border: Border.all(color: p.outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.label,
                    style: TextStyle(
                      color: _palette.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    p.description,
                    style: TextStyle(
                      color: _palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: _palette.accent),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _palette.background,
      appBar: AppBar(
        backgroundColor: _palette.appBar,
        title: Text(
          'Калькулятор дисков штанги',
          style: TextStyle(
            color: _palette.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _buildCalculationTab(),
                  _buildRecordsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  color: _palette.surface,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton(
                        index: 0,
                        title: 'Расчет дисков',
                        icon: Icons.calculate_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        index: 1,
                        title: 'Мои рекорды',
                        icon: Icons.emoji_events_outlined,
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        index: 2,
                        title: 'Настройки',
                        icon: Icons.settings_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarbellVisual extends StatelessWidget {
  final List<double> discs;
  final bool includeLocks;

  const _BarbellVisual({required this.discs, required this.includeLocks});

  @override
  Widget build(BuildContext context) {
    final oneSideDiscs = List<double>.from(discs);

    final int redCount = oneSideDiscs.where((d) => d == 25).length;
    int redIndex = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 103,
          height: 76,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: const [
              Positioned(left: 0, child: BarbellBar()),
              Positioned(left: 79, child: _BarbellBobyshka()),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(-1, 0),
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
                if (includeLocks) const LockWidget(),
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
      width: 24,
      height: 76,
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
  final AppPalette palette;
  const _DiscLegend({required this.discs, required this.palette});

  @override
  Widget build(BuildContext context) {
    final Map<double, int> counts = {};
    for (final d in discs) {
      counts[d] = (counts[d] ?? 0) + 1;
    }

    final sorted = counts.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      color: palette.surface,
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