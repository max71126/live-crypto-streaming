import 'dart:collection';

import 'package:ably_cryptocurrency/ably_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:ably_flutter_plugin/ably_flutter_plugin.dart' as ably;

class DashboardView extends StatefulWidget {
  DashboardView({Key key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    final ablyService = Provider.of<AblyService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Ably"),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble),
            onPressed: () {},
          )
        ],
        bottom: PreferredSize(
          child: Container(
            color: Colors.white,
            height: 1.0,
          ),
          preferredSize: Size.fromHeight(1.0),
        ),
      ),
      body: ablyService == null
          ? Center()
          : Center(
              child: StreamProvider<ably.ConnectionStateChange>.value(
                value: ablyService.connection,
                child: Consumer<ably.ConnectionStateChange>(
                  builder: (context, connection, child) {
                    if (connection == null) {
                      return Center();
                    } else if (connection.event == ably.ConnectionEvent.connected) {
                      return child;
                    }
                    return CircularProgressIndicator();
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: Column(
                        children: ablyService
                            .listenToCoinsPrice()
                            .values
                            .map((Stream<Coin> coinPrices) => CoinGraphItem(stream: coinPrices))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class CoinGraphItem extends StatefulWidget {
  CoinGraphItem({Key key, this.stream}) : super(key: key);
  final Stream<Coin> stream;
  @override
  _CoinGraphItemState createState() => _CoinGraphItemState();
}

class _CoinGraphItemState extends State<CoinGraphItem> {
  Queue<Coin> queue = Queue();

  @override
  void initState() {
    widget.stream.listen((event) {
      if (event != null) {
        setState(() {
          queue.add(event);
        });
        if (queue.length > 100) {
          queue.removeFirst();
        }

        print(queue.length);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(30),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(color: Color(0xffEDEDED).withOpacity(0.05), borderRadius: BorderRadius.circular(8.0)),
      child: queue.isEmpty
          ? Center()
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icon_awesome_twitter.png',
                          height: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "#${queue.last.name}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${queue.last.price}",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25),
                SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    dateFormat: intl.DateFormat.Hms(),
                    intervalType: DateTimeIntervalType.minutes,
                    desiredIntervals: 10,
                    //visibleMinimum: DateTime.now().subtract(Duration(minutes: 2)),
                    axisLine: AxisLine(width: 2, color: Colors.white),
                    majorTickLines: MajorTickLines(color: Colors.transparent),
                  ),
                  primaryYAxis: NumericAxis(
                    desiredIntervals: 6,
                    decimalPlaces: 4,
                    axisLine: AxisLine(width: 2, color: Colors.white),
                    majorTickLines: MajorTickLines(color: Colors.transparent),
                  ),
                  plotAreaBorderColor: Colors.white.withOpacity(0.2),
                  plotAreaBorderWidth: 0.2,
                  series: <LineSeries<Coin, DateTime>>[
                    LineSeries<Coin, DateTime>(
                      width: 3,
                      color: Colors.white,
                      dataSource: queue.toList(),
                      xValueMapper: (Coin coin, _) => coin.dateTime,
                      yValueMapper: (Coin coin, _) => coin.price,
                    )
                  ],
                )
              ],
            ),
    );
  }
}

class CoinPriceData {
  CoinPriceData(this.time, this.price);
  final DateTime time;
  final double price;
}
