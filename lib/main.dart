import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'storage_util.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() => runApp(MyApp());

/// Time-series data type.
class TimeSeries {
  final DateTime time;
  final int value;
  TimeSeries (this.time, this.value);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sendzor data',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: MyHomePage(title: 'Pametni zabojniki'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Position _currentPosition;
  double curlat=0.0;
  double curlng=0.0;

  List dataJSON;
  List CurDataJSON;

  Future<String> getAveSensorData() async {
    var response = await http //za grafikon povprečnih vrednosti
        .get(Uri.encodeFull("http://pametnozodpadki.si/senddata.php?sensor=00FAE453B8E926A1"), headers: {"Accept": "application/json"});

    if (this.mounted) {
      this.setState(() {
        dataJSON = json.decode(response.body);
      });
    }
  }

  Future<String> getCurSensorData() async {
    var response = await http //za grafikon zadnjih meritev
        .get(Uri.encodeFull("http://pametnozodpadki.si/senddata.php?sensor=00FAE453B8E926A1&list=30"), headers: {"Accept": "application/json"});

    if (this.mounted) {
      this.setState(() {
        CurDataJSON = json.decode(response.body);
      });
    }
  }


  Widget chartContainer = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('Chart Viewer')],
  );


  setposition(){
    _getCurrentLocation();
    if (_currentPosition != null) {
      curlat = _currentPosition.latitude;
      curlng = _currentPosition.longitude;
    } else {
      curlat = 46.056946; //Ljubljana
      curlng = 14.505751;
    }
  }

  @override
  void initState() {
    StorageUtil.putString("myCan", "00FAE453B8E926A1");
    setposition();
    this.getAveSensorData();
    this.getCurSensorData();
    super.initState();
  }

  List<LatLng> tappedPoints = [];

  @override
  Widget build(BuildContext context) {

    var markers = tappedPoints.map((latlng) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: latlng,
        builder: (ctx) => Container(
          child: IconButton(
              icon: Icon(Icons.location_on),
              color: Colors.red,
              iconSize: 45.0,
              onPressed: () {
                print('Marker tapped');
                print( StorageUtil.getString("myCan"));
              },
          ),
        ),
      );
    }).toList();

    var size = MediaQuery.of(context).size;

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double itemHeight =
        (size.height - kToolbarHeight - statusBarHeight) / 2;
    final double itemWidth = size.width / 2;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    return MaterialApp(
      title: 'Pametni zabojnik',
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          appBar: AppBar(
            backgroundColor: Colors.lightGreen,
            bottom: TabBar(
              indicatorColor: Colors.red,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.insert_chart)),
                Tab(icon: Icon(Icons.show_chart)),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: Text('Pametni zabojnik'),
          ),
          body: TabBarView(physics: NeverScrollableScrollPhysics(), children:
          [
            //tale je prvi tab z grafom
            new Container(
              color: Colors.white,
              child: Column(
                children: [
                  new Container(
                    child: CurDataJSON == null ? CircularProgressIndicator() : BarchartWidget(),
                  ),
                  new Container(
                    height: 50,
                    child: Text('Polnost zabojnika', style: TextStyle(fontSize: 24)),
                  ),
                  new Container(
                    height: 150,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Card(
                            child: Padding (
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(index.toString()),
                                  Text("Datum:" + CurDataJSON[index]["reading_time"], style: TextStyle(fontSize: 16) ),
                                  Text("Povp. razdalja:" + CurDataJSON[index]["value1"], style: TextStyle(fontSize: 16) ),
                                ],
                              ),
                            )
                        );
                      },
                      itemCount: CurDataJSON.length,
                    ),
                  ),
                ],
              ),
            ),
            //tale je drugi tab z zadnjimi 10timi izpisi
            new Container(
              color: Colors.white,
              child: Column(
                children: [
                  new Container(
                    child: dataJSON == null ? CircularProgressIndicator() : chartWidget(),
                  ),
                  new Container(
                    height: 25,
                    child: Text('Povprečne dnevne vrednosti', style: TextStyle(fontSize: 24)),
                  ),
                  new Container(
                    height: 150,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Card(
                            child: Padding (
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(index.toString()),
                                  Text("Datum:" + dataJSON[index]["reading_time"], style: TextStyle(fontSize: 16) ),
                                  Text("Povp. razdalja:" + dataJSON[index]["value1"], style: TextStyle(fontSize: 16) ),
                                ],
                              ),
                            )
                        );
                      },
                      itemCount: dataJSON.length,
                    ),
                  ),
                ],
              ),
            ),
            new Container(
                child: new FlutterMap(
                  options: new MapOptions(
                      center: new LatLng(curlat, curlng),
                      minZoom: 10.0,
                      onTap: _handleTap
                  ),
                  layers: [
                    new TileLayerOptions(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
                      new MarkerLayerOptions(markers: markers
                      )
                  ]
                )
            ),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              //izvede poizvedbo na server za nove podatke
              getAveSensorData();
              getCurSensorData();
            },
            child: Text('Reload'),
            backgroundColor: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget chartWidget() {
    List<TimeSeries> tsdata = [];
    if (dataJSON != null) {
      for (Map m in dataJSON) {
        try {
          tsdata.add(new TimeSeries(
              DateTime.parse(m['reading_time']), int.parse(m['value1'])));
        } catch (e) {
          print(e.toString());
        }
      }
    } else {
      // Dummy list to prevent dataJSON = NULL
      tsdata.add(new TimeSeries(new DateTime.now(), 0));
    }

    var series = [
      new charts.Series<TimeSeries, DateTime>(
        id: 'Timeline',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeSeries polnost, _) => polnost.time,
        measureFn: (TimeSeries polnost, _) => polnost.value,
        data: tsdata,
      ),
    ];

    var chart = new charts.TimeSeriesChart(
      series,
      animate: true,
    );

    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(32.0),
            child: new SizedBox(
              height: 200.0,
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget BarchartWidget() {
    List<TimeSeries> ctsdata = [];
    if (CurDataJSON != null) {
      for (Map m in CurDataJSON) {
        try {
          ctsdata.add(new TimeSeries(
              DateTime.parse(m['reading_time']), int.parse(m['value1'])));
        } catch (e) {
          print(e.toString());
        }
      }
    } else {
      // Dummy list to prevent dataJSON = NULL
      ctsdata.add(new TimeSeries(new DateTime.now(), 0));
    }

    final desktopSalesData = [
      new TimeSeries(DateTime.fromMicrosecondsSinceEpoch(0), int.parse(dataJSON[0]["value1"])),
    ];

    final tableSalesData = [
      new TimeSeries(DateTime.fromMicrosecondsSinceEpoch(0), 30),
    ];

    var series = [
      new charts.Series<TimeSeries, String>(
        id: 'Polno',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (TimeSeries polnost, _) => "Danes",
        measureFn: (TimeSeries polnost, _) => polnost.value,
        data: desktopSalesData,
      ),
      new charts.Series<TimeSeries, String>(
        id: 'Prazno',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeSeries polnost, _) => "Danes",
        measureFn: (TimeSeries polnost, _) => polnost.value,
        data: tableSalesData,
      ),
    ];

    var chart = new charts.BarChart(
      series,
      animate: true,
      primaryMeasureAxis: new charts.NumericAxisSpec(
        tickProviderSpec: new charts.StaticNumericTickProviderSpec(
          <charts.TickSpec<num>>[
            charts.TickSpec<num>(0),
            charts.TickSpec<num>(25),
            charts.TickSpec<num>(50),
            charts.TickSpec<num>(75),
            charts.TickSpec<num>(100),
          ],
        ),
      ),
      barGroupingType: charts.BarGroupingType.stacked,
    );

    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Padding(
            padding: new EdgeInsets.all(32.0),
            child: new SizedBox(
              height: 200.0,
              child: chart,
            ),
          ),
        ],
      ),
    );
  }



  void _handleTap(LatLng latlng) {
    setState(() {
      tappedPoints.add(latlng);
    });
  }
  _getCurrentLocation() {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
    }).catchError((e) {
      print(e);
      print('getcurrentpositionerror');
    });
  }
}
