import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'note.dart';
import 'storage_util.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charts_flutter/flutter.dart' as charts;


void main() => runApp(MyApp());


class StackedBarChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  StackedBarChart(this.seriesList, {this.animate});

  /// Creates a stacked [BarChart] with sample data and no transition.
  factory StackedBarChart.withSampleData() {
    return new StackedBarChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      seriesList,
      animate: animate,
      barGroupingType: charts.BarGroupingType.stacked,
    );
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final desktopSalesData = [
      new OrdinalSales('Vaš zabojnik', 74),
    ];

    final tableSalesData = [
      new OrdinalSales('Vaš zabojnik', 100-74),
    ];

    return [
      new charts.Series<OrdinalSales, String>(
        id: 'Prazno',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      new charts.Series<OrdinalSales, String>(
        id: 'Polno',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
    ];
  }
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

class SimpleLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  SimpleLineChart(this.seriesList, {this.animate});

  /// Creates a [LineChart] with sample data and no transition.
  factory SimpleLineChart.withSampleData() {
    return new SimpleLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(
        seriesList,
        animate: animate
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearValue, DateTime>> _createSampleData() {
    final data = [
      new LinearValue(new DateTime(2020,5,6), 5),
    ];
    data.add(LinearValue(DateTime.parse("2020-05-07"), 25));
    data.add(LinearValue(DateTime.parse("2020-05-08"), 25));
    data.add(LinearValue(DateTime.parse("2020-05-09"), 25));

    return [
      new charts.Series<LinearValue, DateTime>(
        id: 'Value',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (LinearValue Value, _) => Value.measuredate,
        measureFn: (LinearValue Value, _) => Value.Value,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
class LinearValue {
  final DateTime measuredate;
  final int Value;

  LinearValue(this.measuredate, this.Value);
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

  Widget chartContainer = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('Chart Viewer')],
  );

  //seznam za podatke iz poizvedbe URL
  List<Note> _notes = List<Note>();
  //izvede poizvedbo na serverju
  Future<List<Note>> fecthNotes() async {
    //potegne podatke v obliki JSONa v app
    var url = 'http://pametnozodpadki.si/senddata.php?sensor=00FAE453B8E926A1';//+StorageUtil.getString("myCan");
    print(url);
    var response = await http.get(url);

    var notes = List<Note>();

    if (response.statusCode == 200) {
      var notesJson = json.decode(response.body);
      for (var notesJson in notesJson) {
        notes.add(Note.fromJson(notesJson));
      }
    }
    return notes;
  }

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
  refreshnotes(){
    setposition();
    //izvede poizvedbo na serverju
    fecthNotes().then((value) {
      _notes.clear(); //počisti, da bo vedno samo 10 zadnjih zapisov v seznamu
      setState(() {
        _notes.addAll(value);
      });

    });
    // Put your code here, which you want to execute on onPress event.
  }

  @override


  @override
  void initState() {
    StorageUtil.putString("myCan", "00FAE453B8E926A1");
    refreshnotes();
    super.initState();
  }

  List<Color> _colors = [
    Colors.red,
    Colors.green
  ];

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
                    height: 250,
                    child: StackedBarChart.withSampleData(),
                  ),
                  new Container(
                    height: 250,
                    child: Text('Polnost zabojnika', style: TextStyle(fontSize: 24)),
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
                    height: 150,
                    child: SimpleLineChart.withSampleData(),
                  ),
                  new Container(
                    height: 25,
                    child: Text('Povprečne dnevne vrednosti', style: TextStyle(fontSize: 24)),
                  ),
                  new Container(
                    height: 250,
                    child: ListView.builder(
                      itemBuilder: (context, index){
                        return Card(
                            child: Padding (
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(index.toString()),
                                  Text("Datum/čas:" + _notes[index].Measure_time, style: TextStyle(fontSize: 16) ),
                                  Text("Razdalja:" + _notes[index].Sensor_value.toString(), style: TextStyle(fontSize: 16) ),
                                ],
                              ),
                            )
                        );
                      },
                      itemCount: _notes.length,
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
              refreshnotes();
            },
            child: Text('Reload'),
            backgroundColor: Colors.red,
          ),
        ),
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
