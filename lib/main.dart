import 'package:flutter/material.dart';

void main() {
  runApp(const SaudiStockApp());
}

class SaudiStockApp extends StatelessWidget {
  const SaudiStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'متابع الأسهم السعودية',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const StockHomePage(),
    );
  }
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({super.key});

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  int page = 0;

  final List<Map<String, String>> stocks = [
    {
      'name': 'أرامكو السعودية',
      'symbol': '2222',
      'price': '24.80',
      'change': '+1.22%',
    },
    {
      'name': 'مصرف الراجحي',
      'symbol': '1120',
      'price': '96.40',
      'change': '+0.84%',
    },
    {
      'name': 'سابك',
      'symbol': '2010',
      'price': '58.75',
      'change': '-0.51%',
    },
    {
      'name': 'الأهلي السعودي',
      'symbol': '1180',
      'price': '39.20',
      'change': '+1.03%',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'متابع الأسهم السعودية',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _getPage(),
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

  Widget _getPage() {
    switch (page) {
      case 0:
        return dashboard();
      case 1:
        return placeholderPage(
          'قائمة المتابعة',
          Icons.star,
          'تابع الأسهم المهمة بالنسبة لك',
        );
      case 2:
        return placeholderPage(
          'المحفظة',
          Icons.pie_chart,
          'متابعة الأسهم والكميات ومتوسط سعر الشراء',
        );
      default:
        return placeholderPage(
          'التنبيهات',
          Icons.notifications,
          'تنبيهات الأسعار والمؤشرات الفنية',
        );
    }
  }

  Widget dashboard() {
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
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'مؤشر تاسي',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '11,245.30',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '+0.76%',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'الأسهم',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...stocks.map((stock) {
          final bool positive =
              stock['change']!.startsWith('+');

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  stock['symbol']!.substring(0, 2),
                ),
              ),
              title: Text(
                stock['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(stock['symbol']!),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stock['price']} ر.س',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stock['change']!,
                    style: TextStyle(
                      color: positive
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const Text(
          'البيانات الحالية تجريبية وسيتم ربط بيانات السوق لاحقًا.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget placeholderPage(
    String title,
    IconData icon,
    String description,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
