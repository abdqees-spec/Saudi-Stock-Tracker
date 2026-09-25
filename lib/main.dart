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
      theme: ThemeData.dark(useMaterial3: true),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: StockHomePage(),
      ),
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

  final stocks = const [
    ['أرامكو السعودية', '2222', '27.85', '+1.46%'],
    ['الراجحي', '1120', '98.40', '+0.82%'],
    ['سابك', '2010', '61.70', '-0.48%'],
    ['STC', '7010', '43.25', '+1.12%'],
    ['الأهلي السعودي', '1180', '39.80', '-0.25%'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07111F),
        title: const Text(
          'متابع الأسهم السعودية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Icon(Icons.notifications_none),
          SizedBox(width: 16),
        ],
      ),
      body: page == 0 ? dashboard() : placeholderPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (value) {
          setState(() => page = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'السوق',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'المتابعة',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'المحفظة',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'التنبيهات',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'السوق السعودي',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'نسخة تجريبية • البيانات الحالية Demo',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('مؤشر تاسي TASI'),
                SizedBox(height: 8),
                Text(
                  '11,420.35',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '+0.73%',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'الأسهم',
          style: TextStyle(fontSize: 20, fontWeight
