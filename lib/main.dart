import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';



void main() {
  runApp(CryptoTradingApp());
}

//The main class
class CryptoTradingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Trading',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 19, 77, 115),
        fontFamily: 'Robotomono',
      ),
      debugShowCheckedModeBanner: false,
      home: CryptoListScreen(), //defined below
    );
  }
}

// This class is responsible for the chart screen of the currencies
class CryptoChartScreen extends StatefulWidget {
  final String cryptoName;

  CryptoChartScreen(this.cryptoName);

  @override
  _CryptoChartScreenState createState() => _CryptoChartScreenState();
}

class _CryptoChartScreenState extends State<CryptoChartScreen> {
  List<Map<String, dynamic>> chartData = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchChartData();
  }

//Below function fetchChartData uses coingecko api for crypto data

  Future<void> fetchChartData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.coingecko.com/api/v3/coins/${widget.cryptoName.toLowerCase()}/market_chart?vs_currency=usd&days=7'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['prices'];
        setState(() {
          chartData = data.map((entry) {
            return {
              'time': entry[0],
              'price': entry[1],
            };
          }).toList();
          loading = false;
        });
      } else {
        throw Exception('Failed to load chart data');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        children: [
          Text('${widget.cryptoName} Chart'),
          SizedBox(
            width: 15,
          ),
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                  onPressed: () {},
                  child: Text('Buy')), // will add functionality to buy
              ElevatedButton(onPressed: () {}, child: Text('Sell'))
            ], // will add functionality to sell
          ),
        ],
      )),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        final time = entry.value['time'] as int;
                        final price = entry.value['price'] as double;
                        return FlSpot(time.toDouble(), price);
                      }).toList(),
                      isCurved: true,
                      colors: [Color.fromARGB(228, 22, 25, 28)],
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: chartData
                          .map((entry) => entry['price'] as double)
                          .reduce((curr, next) => curr < next ? curr : next) *
                      0.9,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(enabled: false),
                ),
              ),
            ),
    );
  }
}

//This class is responsible for the first page

class CryptoListScreen extends StatefulWidget {
  @override
  _CryptoListScreenState createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  late Timer _timer;
  late StreamController<List<Map<String, dynamic>>> _streamController;
  List<Map<String, dynamic>> cryptoData = [];
  

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<Map<String, dynamic>>>();
    _timer =
        Timer.periodic(Duration(seconds: 3), (Timer t) => fetchCryptoPrices());
    fetchCryptoPrices();
  }

  @override
  void dispose() {
    _timer.cancel();
    _streamController.close();
    super.dispose();
  }

//Below function uses coingecko api for crypto data

  Future<void> fetchCryptoPrices() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd'));

    if (response.statusCode == 200) {
      final List<dynamic> decodedData = json.decode(response.body);
      final List<Map<String, dynamic>> updatedData = decodedData
          .map((crypto) => {
                'name': crypto['name'],
                'price': crypto['current_price'],
              })
          .toList();
      _streamController.add(updatedData);
    } else {
      throw Exception('Failed to load cryptocurrency prices');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 70,
              ),
              SizedBox(width: 0),
              Text(
                'CryptoMoney',
                style: TextStyle(fontFamily: 'Schyler', fontSize: 60),
              ),
              
            ],
          ),
          backgroundColor: Color.fromARGB(108, 222, 217, 205),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            cryptoData = snapshot.data!;
            return ListView.builder(
              itemCount: cryptoData.length,
              itemBuilder: (context, index) {
                final crypto = cryptoData[index];
                return ListTile(
                  title: Text(crypto['name']),
                  subtitle: Text('\$${crypto['price'].toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CryptoChartScreen(crypto['name']),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      backgroundColor: Color.fromARGB(68, 158, 237, 220),
    );
  }
}
