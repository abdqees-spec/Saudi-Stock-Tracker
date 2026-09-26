import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
void main() {
  runApp(const SaudiStockApp());
}

class SaudiStockApp extends StatelessWidget {
  const SaudiStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متابع الأسهم السعودية V2',
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

  final Set<String> watch = {
    '2222',
    '1120',
  };

  final List<Stock> stocks = const [
    Stock('أرامكو السعودية', '2222', 24.80, 1.22),
    Stock('مصرف الراجحي', '1120', 96.40, 0.84),
    Stock('سابك', '2010', 58.75, -0.51),
    Stock('الأهلي السعودي', '1180', 39.20, 1.03),
    Stock('الاتصالات السعودية', '7010', 44.10, 0.46),
    Stock('معادن', '1211', 54.60, -0.73),
  ];

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
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'التنبيهات',
            ),
          ],
        ),
      ),
    );
  }

  Widget market() {
    return ListView(
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
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مؤشر تاسي',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  '11,245.30',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '+0.76%',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'V2 • البيانات الحالية تجريبية وسيتم ربط بيانات السوق الحقيقية في V3.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stock.price.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${positive ? '+' : ''}${stock.change.toStringAsFixed(2)}%',
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
                  if (watch.contains(stock.symbol)) {
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
                color: watch.contains(stock.symbol)
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
          (stock) => watch.contains(stock.symbol),
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
            subtitle: Text('أرامكو عند 25.00 ر.س'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.show_chart),
            title: Text('اختراق مقاومة'),
            subtitle: Text('الراجحي أعلى من 98.00 ر.س'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.speed),
            title: Text('RSI'),
            subtitle: Text('التشبع الشرائي والبيعي'),
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

class _StockDetailsState extends State<StockDetails> {
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
              '${positive ? '+' : ''}${stock.change.toStringAsFixed(2)}%',
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
                  'محايد',
                ),
                metric(
                  'MACD',
                  '+0.18',
                  'إيجابي',
                ),
                metric(
                  'MA20',
                  '24.35',
                  'فوق المتوسط',
                ),
                metric(
                  'MA50',
                  '23.90',
                  'فوق المتوسط',
                ),
                metric(
                  'MA200',
                  '25.10',
                  'دون المتوسط',
                ),
                metric(
                  'الحجم',
                  '12.4M',
                  'طبيعي',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: level(
                    'الدعم',
                    (stock.price * 0.96)
                        .toStringAsFixed(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: level(
                    'المقاومة',
                    (stock.price * 1.04)
                        .toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                ),
                title: Text(
                  'ملخص فني',
                ),
                subtitle: Text(
                  'المؤشرات في V2 تجريبية وليست توصية شراء أو بيع.',
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget level(
    String title,
    String value,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              '$value ر.س',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockSearch extends SearchDelegate<Stock?> {
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
