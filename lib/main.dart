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
        scaffoldBackgroundColor:
            const Color(0xFF081109),
      ),
      home: const HomePage(),
    );
  }
}

class Stock {
  final String name;
  final String symbol;
  final String? sector;

  const Stock({
    required this.name,
    required this.symbol,
    this.sector,
  });
}

class Quote {
  final double price;
  final double changePercent;
  final double? change;
  final double? open;
  final double? high;
  final double? low;
  final double? previousClose;
  final double? volume;
  final bool delayed;

  const Quote({
    required this.price,
    required this.changePercent,
    this.change,
    this.open,
    this.high,
    this.low,
    this.previousClose,
    this.volume,
    this.delayed = false,
  });
}

class SahmkApi {
  static Map<String, String> get headers => {
        'X-API-Key': sahmkApiKey,
        'Accept': 'application/json',
      };

  static Future<List<Stock>>
      fetchAllTasiCompanies() async {
    if (sahmkApiKey.isEmpty) {
      throw Exception(
        'SAHMK_API_KEY غير موجود في نسخة التطبيق',
      );
    }

    final List<Stock> allStocks = [];

    int offset = 0;
    const int limit = 100;

    while (true) {
      final uri = Uri.parse(
        '$sahmkBaseUrl/companies/'
        '?market=TASI'
        '&limit=$limit'
        '&offset=$offset',
      );

      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 20),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'SAHMK ${response.statusCode}: '
          '${response.body}',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      List<dynamic> rows = [];

      if (decoded is List) {
        rows = decoded;
      } else if (decoded is Map) {
        if (decoded['results'] is List) {
          rows =
              List<dynamic>.from(decoded['results']);
        } else if (decoded['data'] is List) {
          rows =
              List<dynamic>.from(decoded['data']);
        } else if (decoded['companies'] is List) {
          rows = List<dynamic>.from(
            decoded['companies'],
          );
        }
      }

      if (rows.isEmpty) {
        break;
      }

      for (final item in rows) {
        if (item is! Map) continue;

        final map =
            Map<String, dynamic>.from(item);

        final symbol = _stringValue(
          map,
          [
            'symbol',
            'ticker',
            'code',
          ],
        );

        if (symbol.isEmpty) continue;

        final arabicName = _stringValue(
          map,
          [
            'name_ar',
            'arabic_name',
            'nameAr',
          ],
        );

        final englishName = _stringValue(
          map,
          [
            'name',
            'name_en',
            'english_name',
          ],
        );

        final sector = _stringValue(
          map,
          [
            'sector_name_ar',
            'sector',
            'sector_name',
          ],
        );

        allStocks.add(
          Stock(
            name: arabicName.isNotEmpty
                ? arabicName
                : englishName.isNotEmpty
                    ? englishName
                    : symbol,
            symbol: symbol,
            sector:
                sector.isEmpty ? null : sector,
          ),
        );
      }

      if (rows.length < limit) {
        break;
      }

      offset += limit;

      if (offset > 1000) {
        break;
      }
    }

    final unique = <String, Stock>{};

    for (final stock in allStocks) {
      unique[stock.symbol] = stock;
    }

    final result = unique.values.toList();

    result.sort(
      (a, b) => a.symbol.compareTo(b.symbol),
    );

    if (result.isEmpty) {
      throw Exception(
        'لم ترجع SAHMK أي شركات من TASI',
      );
    }

    return result;
  }

  static Future<Quote> fetchQuote(
    String symbol,
  ) async {
    if (sahmkApiKey.isEmpty) {
      throw Exception(
        'SAHMK_API_KEY غير موجود في نسخة التطبيق',
      );
    }

    final uri = Uri.parse(
      '$sahmkBaseUrl/quote/$symbol/',
    );

    final response = await http
        .get(
          uri,
          headers: headers,
        )
        .timeout(
          const Duration(seconds: 20),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'SAHMK ${response.statusCode}: '
        '${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'استجابة غير متوقعة من SAHMK',
      );
    }

    Map<String, dynamic> data =
        Map<String, dynamic>.from(decoded);

    if (data['data'] is Map) {
      data = Map<String, dynamic>.from(
        data['data'],
      );
    }

    final price = _doubleValue(
      data,
      [
        'price',
        'last_price',
        'last',
        'close',
      ],
    );

    if (price == null) {
      throw Exception(
        'لم يتم العثور على السعر في استجابة SAHMK',
      );
    }

    final changePercent = _doubleValue(
          data,
          [
            'change_percent',
            'change_percentage',
            'percent_change',
            'changePercent',
          ],
        ) ??
        0;

    return Quote(
      price: price,
      changePercent: changePercent,
      change: _doubleValue(
        data,
        ['change', 'price_change'],
      ),
      open: _doubleValue(
        data,
        ['open', 'open_price'],
      ),
      high: _doubleValue(
        data,
        ['high', 'high_price'],
      ),
      low: _doubleValue(
        data,
        ['low', 'low_price'],
      ),
      previousClose: _doubleValue(
        data,
        [
          'previous_close',
          'prev_close',
          'previousClose',
        ],
      ),
      volume: _doubleValue(
        data,
        ['volume', 'traded_volume'],
      ),
      delayed: _boolValue(
        data,
        [
          'is_delayed',
          'delayed',
        ],
      ),
    );
  }

  static String _stringValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  static double? _doubleValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(
        value
            .toString()
            .replaceAll(',', '')
            .replaceAll('%', '')
            .trim(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static bool _boolValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is bool) {
        return value;
      }

      if (value != null) {
        final text =
            value.toString().toLowerCase();

        if (text == 'true' ||
            text == '1') {
          return true;
        }
      }
    }

    return false;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState
    extends State<HomePage> {
  int page = 0;

  bool loading = true;
  String? error;

  List<Stock> stocks = [];

  final Set<String> watch = {};

  @override
  void initState() {
    super.initState();
    loadMarket();
  }

  Future<void> loadMarket() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await SahmkApi.fetchAllTasiCompanies();

      if (!mounted) return;

      setState(() {
        stocks = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'السوق السعودي',
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
                tooltip: 'تحديث',
                onPressed:
                    loading ? null : loadMarket,
                icon:
                    const Icon(Icons.refresh),
              ),
            if (stocks.isNotEmpty)
              IconButton(
                tooltip: 'بحث',
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: StockSearch(
                      stocks,
                      openStock,
                    ),
                  );
                },
                icon:
                    const Icon(Icons.search),
              ),
          ],
        ),
        body: [
          marketPage(),
          watchPage(),
          portfolioPage(),
          alertsPage(),
        ][page],
        bottomNavigationBar:
            NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) {
            setState(() {
              page = value;
            });
          },
          destinations: const [
            NavigationDestination(
              icon:
                  Icon(Icons.home_outlined),
              selectedIcon:
                  Icon(Icons.home),
              label: 'السوق',
            ),
            NavigationDestination(
              icon:
                  Icon(Icons.star_outline),
              selectedIcon:
                  Icon(Icons.star),
              label: 'المتابعة',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.pie_chart_outline,
              ),
              selectedIcon:
                  Icon(Icons.pie_chart),
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

  Widget marketPage() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل شركات TASI من SAHMK...',
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.cloud_off,
            size: 60,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'تعذر الاتصال بـ SAHMK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: loadMarket,
            icon:
                const Icon(Icons.refresh),
            label:
                const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: loadMarket,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(16),
        itemCount: stocks.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TASI',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${stocks.length} شركة/سهم',
                      style: const TextStyle(
                        color:
                            Colors.greenAccent,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'قائمة السوق من SAHMK',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (index == 1) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(
                4,
                18,
                4,
                10,
              ),
              child: Text(
                'جميع الأسهم',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            );
          }

          return stockTile(
            stocks[index - 2],
          );
        },
      ),
    );
  }

  Widget stockTile(Stock stock) {
    final selected =
        watch.contains(stock.symbol);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => openStock(stock),
        leading: CircleAvatar(
          child: Text(
            stock.symbol.length >= 2
                ? stock.symbol
                    .substring(0, 2)
                : stock.symbol,
          ),
        ),
        title: Text(
          stock.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          stock.sector == null
              ? stock.symbol
              : '${stock.symbol} • ${stock.sector}',
        ),
        trailing: IconButton(
          onPressed: () {
            setState(() {
              if (selected) {
                watch.remove(stock.symbol);
              } else {
                watch.add(stock.symbol);
              }
            });
          },
          icon: Icon(
            selected
                ? Icons.star
                : Icons.star_border,
            color:
                selected ? Colors.amber : null,
          ),
        ),
      ),
    );
  }

  Widget watchPage() {
    final selected = stocks
        .where(
          (stock) =>
              watch.contains(stock.symbol),
        )
        .toList();

    if (selected.isEmpty) {
      return const Center(
        child: Text(
          'أضف الأسهم إلى المتابعة ⭐',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        Text(
          '${selected.length} سهم في المتابعة',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...selected.map(stockTile),
      ],
    );
  }

  Widget portfolioPage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 70,
              color: Colors.greenAccent,
            ),
            SizedBox(height: 15),
            Text(
              'المحفظة',
              style: TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'سنربط المحفظة بالأسهم الحقيقية في المرحلة التالية.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget alertsPage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 70,
              color: Colors.greenAccent,
            ),
            SizedBox(height: 15),
            Text(
              'التنبيهات',
              style: TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'تنبيهات السعر والمؤشرات ستضاف بعد تثبيت اتصال بيانات السوق.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void openStock(Stock stock) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StockDetails(stock: stock),
      ),
    );
  }
}

class StockDetails
    extends StatefulWidget {
  final Stock stock;

  const StockDetails({
    super.key,
    required this.stock,
  });

  @override
  State<StockDetails> createState() =>
      _StockDetailsState();
}

class _StockDetailsState
    extends State<StockDetails> {
  Quote? quote;
  bool loading = true;
  String? error;
  int period = 0;

  @override
  void initState() {
    super.initState();
    loadQuote();
  }

  Future<void> loadQuote() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await SahmkApi.fetchQuote(
        widget.stock.symbol,
      );

      if (!mounted) return;

      setState(() {
        quote = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.stock.name),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed:
                  loading ? null : loadQuote,
              icon:
                  const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: loadQuote,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(16),
            children: [
              Text(
                widget.stock.symbol,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              if (widget.stock.sector !=
                  null)
                Text(
                  widget.stock.sector!,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 15),

              if (loading)
                const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(25),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text(
                          'جاري جلب السعر من SAHMK...',
                        ),
                      ],
                    ),
                  ),
                ),

              if (error != null)
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color:
                              Colors.orangeAccent,
                          size: 45,
                        ),
                        const SizedBox(
                            height: 10),
                        const Text(
                          'تعذر جلب سعر السهم',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                            height: 8),
                        SelectableText(
                          error!,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                            height: 12),
                        FilledButton(
                          onPressed: loadQuote,
                          child: const Text(
                            'إعادة المحاولة',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (quote != null)
                quoteCard(),

              const SizedBox(height: 16),

              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('يومي'),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('أسبوعي'),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('شهري'),
                  ),
                  ButtonSegment(
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

              const SizedBox(height: 16),

              const Card(
                child: SizedBox(
                  height: 170,
                  child: Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 80,
                          color:
                              Colors.greenAccent,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'الرسم البياني في المرحلة التالية',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (quote != null)
                marketDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget quoteCard() {
    final q = quote!;
    final positive =
        q.changePercent >= 0;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'السعر',
              style:
                  TextStyle(color: Colors.grey),
            ),
            Text(
              '${q.price.toStringAsFixed(2)} ر.س',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${positive ? '+' : ''}'
              '${q.changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: positive
                    ? Colors.greenAccent
                    : Colors.redAccent,
              ),
            ),
            if (q.delayed) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 17,
                    color:
                        Colors.orangeAccent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'البيانات متأخرة حسب باقة SAHMK',
                    style: TextStyle(
                      color:
                          Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget marketDetails() {
    final q = quote!;

    return Column(
      children: [
        const SizedBox(height: 8),
        const Align(
          alignment:
              Alignment.centerRight,
          child: Text(
            'بيانات التداول',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        detail(
          'الافتتاح',
          formatPrice(q.open),
        ),
        detail(
          'الأعلى',
          formatPrice(q.high),
        ),
        detail(
          'الأدنى',
          formatPrice(q.low),
        ),
        detail(
          'الإغلاق السابق',
          formatPrice(q.previousClose),
        ),
        detail(
          'حجم التداول',
          q.volume == null
              ? '-'
              : q.volume!
                  .toStringAsFixed(0),
        ),
        const SizedBox(height: 15),
        const Card(
          child: ListTile(
            leading:
                Icon(Icons.info_outline),
            title:
                Text('مصدر البيانات'),
            subtitle: Text(
              'بيانات السعر من SAHMK API. لا تمثل توصية شراء أو بيع.',
            ),
          ),
        ),
      ],
    );
  }

  Widget detail(
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String formatPrice(double? value) {
    if (value == null) {
      return '-';
    }

    return '${value.toStringAsFixed(2)} ر.س';
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
        icon:
            const Icon(Icons.clear),
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
    final search =
        query.trim().toLowerCase();

    final results = stocks.where(
      (stock) {
        return stock.name
                .toLowerCase()
                .contains(search) ||
            stock.symbol
                .toLowerCase()
                .contains(search);
      },
    ).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final stock =
              results[index];

          return ListTile(
            title:
                Text(stock.name),
            subtitle:
                Text(stock.symbol),
            trailing: const Icon(
              Icons.chevron_left,
            ),
            onTap: () {
              close(context, stock);
              openStock(stock);
            },
          );
        },
      ),
    );
  }
}                                      