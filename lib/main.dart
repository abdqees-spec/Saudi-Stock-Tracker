import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String sahmkApiKey =
    String.fromEnvironment('SAHMK_API_KEY');

const String sahmkBaseUrl =
    'https://api.sahmk.sa/api/v1';

void main() {
  runApp(const SaudiStockApp());
}

class SaudiStockApp extends StatelessWidget {
  const SaudiStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متابع الأسهم السعودية V3',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF081109),
      ),
      home: const HomePage(),
    );
  }
}

class Stock {
  final String name;
  final String symbol;
  final double price;
  final double change;

  const Stock(
    this.name,
    this.symbol,
    this.price,
    this.change,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  bool isLoading = false;
  String? apiError;
  DateTime? lastUpdate;

  final Set<String> watch = {
    '2222',
    '1120',
  };

  List<Stock> stocks = [
    const Stock('أرامكو السعودية', '2222', 24.80, 1.22),
    const Stock('مصرف الراجحي', '1120', 96.40, 0.84),
    const Stock('سابك', '2010', 58.75, -0.51),
    const Stock('الأهلي السعودي', '1180', 39.20, 1.03),
    const Stock('الاتصالات السعودية', '7010', 44.10, 0.46),
    const Stock('معادن', '1211', 54.60, -0.73),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMarketData();
    });
  }

  Future<Stock> fetchStock(Stock stock) async {
    final response = await http.get(
      Uri.parse(
        '$sahmkBaseUrl/quote/${stock.symbol}/',
      ),
      headers: {
        'X-API-Key': sahmkApiKey,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'SAHMK error ${response.statusCode}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected SAHMK response',
      );
    }

    final data = decoded;

    final price = _readDouble(
      data,
      [
        'price',
        'last_price',
        'last',
        'close',
      ],
    );

    final change = _readDouble(
      data,
      [
        'change_percent',
        'changePercent',
        'percent_change',
        'change_percentage',
      ],
    );

    return Stock(
      data['name']?.toString() ?? stock.name,
      stock.symbol,
      price ?? stock.price,
      change ?? stock.change,
    );
  }

  double? _readDouble(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(
        value
            .toString()
            .replaceAll('%', '')
            .replaceAll(',', '')
            .trim(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  Future<void> loadMarketData() async {
    if (sahmkApiKey.isEmpty) {
      setState(() {
        apiError =
            'SAHMK_API_KEY غير موجود في نسخة التطبيق.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      apiError = null;
    });

    try {
      final updatedStocks =
          await Future.wait(
        stocks.map(fetchStock),
      );

      if (!mounted) return;

      setState(() {
        stocks = updatedStocks;
        isLoading = false;
        lastUpdate = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        apiError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'السوق',
      'المتابعة',
      'المحفظة',
      'التنبيهات',
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            titles[page],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            if (page == 0)
              IconButton(
                tooltip: 'تحديث الأسعار',
                onPressed:
                    isLoading ? null : loadMarketData,
                icon: const Icon(Icons.refresh),
              ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: StockSearch(
                    stocks,
                    openStock,
                  ),
                );
              },
            ),
          ],
        ),
        body: [
          market(),
          watchPage(),
          portfolio(),
          alerts(),
        ][page],
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) {
            setState(() {
              page = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'السوق',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              selectedIcon: Icon(Icons.star),
              label: 'المتابعة',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'المحفظة',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.notifications_outlined,
              ),
              selectedIcon: Icon(
                Icons.notifications,
              ),
              label: 'التنبيهات',
            ),
          ],
        ),
      ),
    );
  }

  Widget market() {
    return RefreshIndicator(
      onRefresh: loadMarketData,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'نظرة عامة على السوق',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (isLoading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'جاري تحديث بيانات السوق...',
                    ),
                  ],
                ),
              ),
            ),

          if (apiError != null)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.orangeAccent,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تعذر تحديث بيانات SAHMK',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      apiError!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: loadMarketData,
                      icon:
                          const Icon(Icons.refresh),
                      label:
                          const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات الأسهم السعودية',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    apiError == null &&
                            lastUpdate != null
                        ? 'متصل بـ SAHMK'
                        : 'بانتظار بيانات SAHMK',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: apiError == null &&
                              lastUpdate != null
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                  if (lastUpdate != null)
                    Text(
                      'آخر تحديث: '
                      '${lastUpdate!.hour.toString().padLeft(2, '0')}:'
                      '${lastUpdate!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'الأسهم',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          ...stocks.map(stockTile),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              lastUpdate != null
                  ? 'V3 • بيانات الأسهم من SAHMK API.'
                  : 'V3 • سيتم استبدال القيم الاحتياطية عند نجاح الاتصال بـ SAHMK.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget stockTile(Stock stock) {
    final bool positive = stock.change >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        onTap: () {
          openStock(stock);
        },
        leading: CircleAvatar(
          child: Text(
            stock.symbol.substring(0, 2),
          ),
        ),
        title: Text(
          stock.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(stock.symbol),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${stock.price.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${positive ? '+' : ''}'
                  '${stock.change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: positive
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  if (watch.contains(
                    stock.symbol,
                  )) {
                    watch.remove(stock.symbol);
                  } else {
                    watch.add(stock.symbol);
                  }
                });
              },
              icon: Icon(
                watch.contains(stock.symbol)
                    ? Icons.star
                    : Icons.star_border,
                color:
                    watch.contains(stock.symbol)
                        ? Colors.amber
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget watchPage() {
    final items = stocks
        .where(
          (stock) =>
              watch.contains(stock.symbol),
        )
        .toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'أضف الأسهم للمفضلة من صفحة السوق',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'قائمة المتابعة',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(stockTile),
      ],
    );
  }

  Widget portfolio() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'المحفظة التجريبية',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text('القيمة الحالية'),
                SizedBox(height: 6),
                Text(
                  '25,730 ر.س',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+730 ر.س (+2.92%)',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('أرامكو السعودية'),
            subtitle: Text('300 سهم'),
            trailing: Text('7,440 ر.س'),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('مصرف الراجحي'),
            subtitle: Text('100 سهم'),
            trailing: Text('9,640 ر.س'),
          ),
        ),
        Card(
          child: ListTile(
            title: Text('سابك'),
            subtitle: Text('100 سهم'),
            trailing: Text('5,875 ر.س'),
          ),
        ),
      ],
    );
  }

  Widget alerts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'التنبيهات',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.price_change),
            title: Text('تنبيه السعر'),
            subtitle:
                Text('أرامكو عند 25.00 ر.س'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.show_chart),
            title: Text('اختراق مقاومة'),
            subtitle: Text(
              'الراجحي أعلى من 98.00 ر.س',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.speed),
            title: Text('RSI'),
            subtitle: Text(
              'التشبع الشرائي والبيعي',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('حجم التداول'),
            subtitle: Text(
              'ارتفاع غير معتاد في حجم التداول',
            ),
          ),
        ),
      ],
    );
  }

  void openStock(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return StockDetails(
            stock: stock,
          );
        },
      ),
    );
  }
}

class StockDetails extends StatefulWidget {
  final Stock stock;

  const StockDetails({
    super.key,
    required this.stock,
  });

  @override
  State<StockDetails> createState() {
    return _StockDetailsState();
  }
}

class _StockDetailsState
    extends State<StockDetails> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final bool positive = stock.change >= 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(stock.name),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              stock.symbol,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              '${stock.price.toStringAsFixed(2)} ر.س',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${positive ? '+' : ''}'
              '${stock.change.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 18,
                color: positive
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('يومي'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('أسبوعي'),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('شهري'),
                ),
                ButtonSegment<int>(
                  value: 3,
                  label: Text('سنوي'),
                ),
              ],
              selected: {period},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() {
                  period = value.first;
                });
              },
            ),

            const SizedBox(height: 18),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: SizedBox(
                  height: 140,
                  child: Center(
                    child: Icon(
                      Icons.show_chart,
                      size: 110,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'المؤشرات الفنية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                metric(
                  'RSI',
                  '57',
                  'تجريبي',
                ),
                metric(
                  'MACD',
                  '+0.18',
                  'تجريبي',
                ),
                metric(
                  'MA20',
                  '24.35',
                  'تجريبي',
                ),
                metric(
                  'MA50',
                  '23.90',
                  'تجريبي',
                ),
                metric(
                  'MA200',
                  '25.10',
                  'تجريبي',
                ),
                metric(
                  'الحجم',
                  '12.4M',
                  'تجريبي',
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                ),
                title: Text(
                  'المؤشرات الفنية',
                ),
                subtitle: Text(
                  'السعر ونسبة التغير يتم تحديثهما من SAHMK عند نجاح الاتصال. المؤشرات الفنية والرسم البياني ما زالت تجريبية في هذه المرحلة.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget metric(
    String title,
    String value,
    String status,
  ) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF142017),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StockSearch
    extends SearchDelegate<Stock?> {
  final List<Stock> stocks;
  final void Function(Stock) openStock;

  StockSearch(
    this.stocks,
    this.openStock,
  );

  @override
  String get searchFieldLabel =>
      'ابحث باسم الشركة أو الرمز';

  @override
  List<Widget>? buildActions(
    BuildContext context,
  ) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(
    BuildContext context,
  ) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(
        Icons.arrow_back,
      ),
    );
  }

  @override
  Widget buildResults(
    BuildContext context,
  ) {
    return resultList(context);
  }

  @override
  Widget buildSuggestions(
    BuildContext context,
  ) {
    return resultList(context);
  }

  Widget resultList(
    BuildContext context,
  ) {
    final results = stocks.where(
      (stock) {
        return stock.name.contains(query) ||
            stock.symbol.contains(query);
      },
    ).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        children: results.map(
          (stock) {
            return ListTile(
              title: Text(stock.name),
              subtitle: Text(stock.symbol),
              trailing: Text(
                '${stock.price.toStringAsFixed(2)} ر.س',
              ),
              onTap: () {
                close(context, stock);
                openStock(stock);
              },
            );
          },
        ).toList(),
      ),
    );
  }
}