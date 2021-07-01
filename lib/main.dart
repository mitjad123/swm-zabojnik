import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'storage_util.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageUtil.getInstance();
  runApp(MyApp());
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

List<Sensordata> sensordataFromJson(String str) =>
    List<Sensordata>.from(json.decode(str).map((x) => Sensordata.fromJson(x)));

String sensordataToJson(List<Sensordata> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Sensordata {
  Sensordata({
    this.sensor,
    this.tip,
    this.naslov,
    this.data,
  });

  String sensor;
  String tip;
  String naslov;
  List<Datum> data;

  factory Sensordata.fromJson(Map<String, dynamic> json) => Sensordata(
    sensor: json["sensor"] == null ? null : json["sensor"],
    tip: json["tip"] == null ? null : json["tip"],
    naslov: json["naslov"] == null ? null : json["naslov"],
    data: json["data"] == null
        ? null
        : List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "sensor": sensor == null ? null : sensor,
    "tip": tip == null ? null : tip,
    "naslov": naslov == null ? null : naslov,
    "data": data == null
        ? null
        : List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class Datum {
  Datum({
    this.value,
    this.readingTime1,
  });

  String value;
  String readingTime1;

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    value: json["value"] == null ? null : json["value"],
    readingTime1: json["reading_time1"] == null ? null : json["reading_time1"],
  );

  Map<String, dynamic> toJson() => {
    "value": value == null ? null : value,
    "reading_time1": readingTime1 == null ? null : readingTime1,
  };
}

class ListItem<T> {
  bool isSelected = false; //Selection property to highlight or not
  T data; //Data
  ListItem(this.data); //Constructor to assign the data
}

class _CdataJSONlist {
  final List<_CdataJSON> CdataJSONitems;

  _CdataJSONlist ({
    this.CdataJSONitems,
  });

  factory _CdataJSONlist.fromJson(List<dynamic> parsedJson) {

    List<_CdataJSON> CdataJSONitems = new List<_CdataJSON>();
    CdataJSONitems = parsedJson.map((i)=>_CdataJSON.fromJson(i)).toList();

    return new _CdataJSONlist(
        CdataJSONitems: CdataJSONitems
    );
  }
}

class _CdataJSON{
  final String sensor;
  final String tip;
  final String naslov;
  final List<_Cdata> Cdata;

  _CdataJSON ({this.sensor, this.tip, this.naslov, this.Cdata});

  factory _CdataJSON.fromJson(Map<String, dynamic> parsedJson){

    var list = parsedJson['Cdata'] as List;
    print(list.runtimeType);
    List<_Cdata> CdataList = list.map((i) => _Cdata.fromJson(i)).toList();


    return new _CdataJSON(
        sensor: parsedJson['sensor'],
        tip: parsedJson['tip'],
        naslov: parsedJson['naslov'],
        Cdata: CdataList
    );
  }
}

class _Cdata{
  String value1;
  String reading_time1;

  _Cdata({this.value1, this.reading_time1});

  factory _Cdata.fromJson(Map<String, dynamic> parsedJson){
    return _Cdata(
        value1:parsedJson['value'],
        reading_time1:parsedJson['reading_time1']
    );
  }

}


class _BCData {
  _BCData(this.sensor, this.value, this.tip, this.naslov,this.segmentColor);

  final String sensor;
  final int value;
  final String tip;
  final String naslov;
  final Color segmentColor;
}

class _LCData {
  _LCData(this.reading_time, this.value);

  final DateTime reading_time;
  final int value;
}


class _MyHomePageState extends State<MyHomePage> {

  //razširjen list, z dodatno lastnostjo Selected
  List<ListItem<String>> list; //https://medium.com/@gadepalliaditya1998/item-selection-in-list-view-on-tap-in-flutter-using-listview-builder-612f6608505a
  List<ListItem<String>> favIDs;   //list za moje shranjene zabojnike, max 4

  List<_BCData> BarChartData = [];

  var AveDataJSON = []; //ker je bil nek error https://stackoverflow.com/questions/51177294/flutter-the-getter-length-was-called-on-null
  List CurDataJSON = [];
  List SensorListJSON = [];
  String mojstring;

  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final postaController = TextEditingController();
  final naslovController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    postaController.dispose();
    naslovController.dispose();
    super.dispose();
  }


  favIDsave() {
    int i = 0;
    for (i = 3; i > 0; i--) { //šifta shranjene zabojnike , četrti pade ven, ker so lahko max štirje
      if (favIDs[i-1].data =="") //če je spodnji odajte nove zabojnike, je ostanek od default praznega seznama in zato ga briši
        favIDs[i-1].data="";
      favIDs[i].data = favIDs[i-1].data;
      StorageUtil.putString("favID" + i.toString(),favIDs[i].data); //zapiše že shranjene zavojnike na nove pozicije
    }
    for (i = 0; i < list.length ; i++) { //šifta shranjene zabojnike , četrti pade ven, ker so lahko max štirje
      if (list[i].isSelected) {
        list[i].isSelected = !list[i].isSelected;
        favIDs[0].data = list[i].data;
        StorageUtil.putString("favID0", list[i].data); //na prvo pozicijo pa shrani sedaj izbran zabojnik
        break;
      }
    }
    if (i==list.length-1)
      print("Noben izbran!");

  }

  favIDdel() {

    int i = 0;
    for (i = 0; i < 3 ; i++) { //išče označenega, zihr je eden, ker sicer ne bi bili tukaj
      if (favIDs[i].isSelected) {
        favIDs[i].isSelected = !favIDs[i].isSelected; //ga odoznači, ker ga ne bo več
        break;
      }
    }
    int j = i; //i sedaj pove, kateri je bil označen oz. zbrisan
    for (i = j; i < 3; i++) { //od j-tega gor
      favIDs[i].data = favIDs[i+1].data; //naslednjega daš na izbrisano mesto itd.
      StorageUtil.putString("favID" + i.toString(),favIDs[i].data); //zapiše že shranjene zavojnike na nove pozicije
    }

    favIDs[3].data=""; //četrtega pa sprazni
    StorageUtil.putString("favID3",""); //četrtega zapiše

    if (j==0) { //če si brisal edinega prvega
      favIDs[0].data = "";
      StorageUtil.putString("favID0",favIDs[0].data);
    }
    this.getAveSensorData();
    this.getCurSensorData();
    this.getSensorListData();

  }

  Future getSensorListData() async {

    var url = Uri.parse('https://pametnozodpadki.si/getsensorlist.php?posta='+(postaController.text)+'&naslov='+(naslovController.text));
    print(url);
    var response = await http
        .get(url, headers: {"Accept": "application/json"});
    try {
      if (response.statusCode == 200) {
        this.setState(() {
          SensorListJSON = jsonDecode(response.body);
          list.length = SensorListJSON.length; //tukaj napolni seznam zabojnikov za zadnji tab listview
          list.clear();
          for (int index = 0; index < SensorListJSON.length; index++) {
            list.add(ListItem<String>(SensorListJSON[index]["id"]+" / "+SensorListJSON[index]["tip"]+" / "+SensorListJSON[index]["naslov"]));
          }
        });
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      throw Exception('Failed');
    }
  }

  Future getAveSensorData() async {
    var url;
    String favList="";
    if (favIDs[0].data != "")
      favList = favIDs[0].data.substring(0,favIDs[0].data.indexOf(' / '));
    for (int i = 1; i < 4; i++) {
      if (favIDs[i].data != "")
        favList = favList + ","+ favIDs[i].data.substring(0,favIDs[i].data.indexOf(' / '));
    }
    favList = favList + "";

    if (favList != "") {
        url = Uri.parse('https://pametnozodpadki.si/senddata.php?sensor='+ favList);
        print (url);

        var response = await http
            .get(url, headers: {"Accept": "application/json"});
        try {
          if (response.statusCode == 200) {
            this.setState(() {
              //AveDataJSON = jsonDecode(response.body);
              AveDataJSON = sensordataFromJson(response.body);
            });
          } else {
            throw Exception('Failed');
          }
        } catch (e) {
          throw Exception('Failed');
        }
    }
    else
      AveDataJSON = null;

  }

  Future getCurSensorData() async {
    var url;
    String favList="";
    if (favIDs[0].data != "")
      favList = favIDs[0].data.substring(0,favIDs[0].data.indexOf(' / '));
    for (int i = 1; i < 4; i++) {
      if (favIDs[i].data != "")
        favList = favList + ","+ favIDs[i].data.substring(0,favIDs[i].data.indexOf(' / '));
    }
    favList = favList + "";

    if (favList != "") {
      url = Uri.parse('https://pametnozodpadki.si/senddataCUR.php?sensor='+ favList);
      print (url);

      var response = await http
          .get(url, headers: {"Accept": "application/json"});
      try {
        if (response.statusCode == 200) {
          this.setState(() {
            CurDataJSON = jsonDecode(response.body);
          });
        } else {
          throw Exception('Failed');
        }
      } catch (e) {
        throw Exception('Failed');
      }
    }
    else
      CurDataJSON = null;
  }


  Widget chartContainer = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('Chart Viewer')],
  );


  @override
  void initState() { //sedem mest za shranjene zabojnike

    favIDs = [];
    if (StorageUtil.getString("favID0".toString())=="") //da dodaš vsaj en shranjen default zabojnik
      StorageUtil.putString("favID0".toString(),"");
    for (int i = 0; i < 4; i++) { //napolni list shranjenih zabojnikov s shranjenimi ID ji
      favIDs.add(ListItem<String>("$i"));
      favIDs[i].data = StorageUtil.getString("favID"+i.toString());
    }

    list = []; //da naredi prazen list, ki se nato napolni s seznamom zabijnikov v getSensorListData
    for (int i = 0; i < 10; i++)
      list.add(ListItem<String>("$i"));

    this.getCurSensorData();
    this.getAveSensorData();
    this.getSensorListData();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    var size = MediaQuery.of(context).size;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double itemHeight =
        (size.height - kToolbarHeight - statusBarHeight) / 2;
    final double itemWidth = size.width / 2;
    //okno O projektu
    final List<Widget> aboutBoxChildren = <Widget>[
      SizedBox(
        height: 20,
      ),
      Text('Pametno z odpadki'),
      Text('Študentski inovativni projekti za družbeno korist 2016-2020'),
      RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
                style: TextStyle(color: Theme.of(context).accentColor),
                text: 'http://www.pametnozodpadki.si'),
          ],
        ),
      ),
      Image.asset("assets/logo1.jpg", width: 100.0, height:100.0),
      Image.asset("assets/logo2.jpg", width: 100.0, height:100.0),
      Image.asset("assets/logo3.jpg", width: 100.0, height:100.0)
    ];
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    return MaterialApp(
      title: 'Pametni zabojnik',
      home: DefaultTabController(
        length: 3, // na koncu 4 tabi
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            //bar na vrhu za tabe, vsak tab ima svojo ikono
            backgroundColor: Colors.lightGreen,
            bottom: TabBar(
              indicatorColor: Colors.red,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.insert_chart)),
                Tab(icon: Icon(Icons.show_chart)),
                //Tab(icon: Icon(Icons.map_outlined)),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: Text('Pametni zabojnik'),
          ),
          drawer: Drawer(
            //Gumb hamburger kjer imaš podatke o aplikaciji
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  child: SingleChildScrollView(
                    child: SafeArea(
                      child: Column(
                        children: <Widget>[
                          AboutListTile(
                            child: Text('O aplikaciji'),
                            icon: Icon(
                              Icons.info,
                            ),
                            applicationIcon: const SizedBox(
                              width: 100,
                              height: 100,
                              child: Image(
                                image: AssetImage('assets/logo100.jpg'),
                              ),
                            ),
                            applicationName: 'Pametno z odpadki',
                            applicationVersion: '1.2.0',
                            applicationLegalese: '©2020 Projekt Pametno upravljanje z odpadki',
                            aboutBoxChildren: aboutBoxChildren,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Exit'),
                  onTap: ()=> exit(0),
                ),
              ],
            ),
          ),
          body: TabBarView(children:
          [
            //tale je prvi tab z grafom
            new Container(
              color: Colors.white,
              child: (CurDataJSON != null)
                ? Column(
                children: [
                  new Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        new Container(
                          child: CurDataJSON == null ? CircularProgressIndicator() : BarchartWidget(),
                        ),
                      ],
                    ),
                  ),
                  new Container(
                    height: itemHeight*0.15,
                    child:  TextButton.icon(
                        label: Text('Osveži podatke'),
                        icon: Icon(Icons.refresh),
                        style: TextButton.styleFrom(
                          primary: Colors.red,
                        ),
                        onPressed: () {
                          this.getCurSensorData();
                        }),
                  ),
                ],
              )
              : Column(
                children: [
                  new Container(
                    height: itemHeight,
                    alignment: Alignment.center,
                    child: Text('Čakam podatke ... Ste izbrali svoje zabojnike?', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                  ),
                ]
              )
            ),
            //tale je drugi tab z zadnjimi 10timi izpisi
            new Container(
             child: new SingleChildScrollView(
              child:  (AveDataJSON.length > 0)
                ? Column(
                children: [
                  new Container(
                    height: ((AveDataJSON != null) && (AveDataJSON.length > 0)) ? itemHeight*0.8 : 0,
                    child: ((AveDataJSON != null) && (AveDataJSON.length > 0)) ? LinechartWidget(0) : null,
                  ),
                  new Container(
                    height: ((AveDataJSON != null) && (AveDataJSON.length > 1)) ? itemHeight*0.8 : 0,
                    child: ((AveDataJSON != null) && (AveDataJSON.length > 1)) ? LinechartWidget(1) : null,
                  ),
                  new Container(
                    height: ((AveDataJSON != null) && (AveDataJSON.length > 2)) ? itemHeight*0.8 : 0,
                    child: ((AveDataJSON != null) && (AveDataJSON.length > 2)) ? LinechartWidget(2) : null,
                  ),
                  new Container(
                    height: ((AveDataJSON != null) && (AveDataJSON.length > 3)) ? itemHeight*0.8 : 0,
                    child: ((AveDataJSON != null) && (AveDataJSON.length > 3)) ? LinechartWidget(3) : null,
                  ),
                  new Container(
                    height: itemHeight*0.15,
                    child:  TextButton.icon(
                        label: Text('Osveži podatke'),
                        icon: Icon(Icons.refresh),
                        style: TextButton.styleFrom(
                          primary: Colors.red,
                        ),
                        onPressed: () {
                          this.getAveSensorData();
                        }),
                  ),
                  new Container(
                    height: itemHeight*0.8,
                    //height: MediaQuery.of(context).size.height * 0.6,
                    child: ListView.builder(
                      itemCount: AveDataJSON[0].data.length,
                      itemBuilder: (context, index){
                        return Card(
                            child: Padding (
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[ //seznam prvega shranjenega senzorja, zgolj za čekiranje, so pa po datumu v obraznem vrstnem redu
                                  Text(AveDataJSON[0].sensor+ " " +AveDataJSON[0].tip+ " " +AveDataJSON[0].naslov),
                                  Text("Datum: " + AveDataJSON[0].data[AveDataJSON[0].data.length-1-index].readingTime1, style: TextStyle(fontSize: 16) ),
                                  Text("Povp. razdalja: " + AveDataJSON[0].data[AveDataJSON[0].data.length-1-index].value, style: TextStyle(fontSize: 16) ),
                                ],
                              ),
                            )
                        );
                      },
                    ),
                  ), //konec kontejnerja
                ],
              )
              : Column(
                  children: [
                    new Container(
                      height: itemHeight,
                      alignment: Alignment.center,
                      child: Text('Čakam podatke ... Ste izbrali svoje zabojnike?', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                  ),
                  ]
              )
             )
            ),
            //tole je tretji tab
            /*new Container(
                child: new FlutterMap(
                  options: new MapOptions(
                      center: new LatLng(curlat, curlng),
                      minZoom: 10.0,
                      onTap: _handleTap
                  ),
                  layers: [
                    new TileLayerOptions(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
                      new MarkerLayerOptions(markers: [//]markers
                          new Marker(
                          width: 45.0,
                          height: 45.0,
                          point: new LatLng(curlat, curlng),
                          builder: (context) => new Container(
                            child: IconButton(
                              icon: Icon(Icons.my_location),
                              color: Colors.red,
                              iconSize: 45.0,
                              onPressed: () {
                                print('Marker tapped');
                              },
                            ),
                          ))]
                      )
                  ]
                )
            ), */
            //tole je čerti tab
            new Container(
                height: itemHeight,
                color: Colors.white,
                child:
                  Column(
                    children: [
                      //rows
                      new Container(
                        height: itemHeight*0.1,
                        child: Text("Vnesi poštno št. ali del številke", style: TextStyle(fontSize: 20)),
                      ),
                      new Container(
                        height: itemHeight*0.1,
                        child: TextField (
                          onSubmitted: (value) {
                            this.getSensorListData();
                            print("enter?");
                          },
                          controller: postaController,
                          style: new TextStyle(fontSize:20.0),
                        ),
                      ),
                      new Container(
                        height: itemHeight*0.1,
                        child: Text("Vnesi del imena ulice", style: TextStyle(fontSize: 20)),
                      ),
                      new Container(
                        height: itemHeight*0.1,
                        child: TextField(
                          controller: naslovController,
                          onSubmitted: (value) {
                            this.getSensorListData();
                            print("enter?");
                          },
                          style: new TextStyle(fontSize:20.0),
                        ),
                        ),
                      new Container(
                        height: itemHeight*0.1,
                        child: TextButton.icon(
                            label: Text('Poišči zabojnike!'),
                            icon: Icon(Icons.search),
                            style: TextButton.styleFrom(
                              primary: Colors.red,
                            ),
                            onPressed: () {
                              print('Search button tapped');
                              this.getSensorListData();
                          }),
                      ),
                      new Container(
                        height: itemHeight*0.5,
                        child: Tooltip(
                            message: 'S klikom na posamezni zabojnik ga odznačite, s poovnim klikom odoznačite. Ko označite tistega, ki ga želite dodati v seznam svojih priljubljenih zabojnikov, pritisnite ta gumb.',
                            child: (SensorListJSON.length > 0)
                             ?ListView.builder(
                              itemCount: SensorListJSON.length,
                              itemBuilder: _getListItemTile,
                            )
                            :Container(
                              height: itemHeight,
                              child: Text('Čakam podatke oz. ni zadetkov iskanja ...', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                            ),
                        ),
                      ),
                      new Container(
                        height: itemHeight*0.15,
                        child:  TextButton.icon(
                            label: Text('Dodaj izbranega med moje zabojnike'),
                            icon: Icon(Icons.save_alt),
                            style: TextButton.styleFrom(
                              primary: Colors.red,
                            ),
                            onPressed: () {
                              print('Dodaj označeno button tapped');
                              this.favIDsave();
                              this.getSensorListData();
                              this.getCurSensorData();
                              this.getAveSensorData();
                            }), //konc texbutona
                        ),
                      new Container(
                        height: itemHeight*0.5,
                        child: ListView.builder(
                            itemCount: favIDs.length,
                            itemBuilder:   _getFavListItemTile,
                        ),
                      ),
                      new Container(
                        height: itemHeight*0.15,
                        child:  TextButton.icon(
                            label: Text('Izbriši izbranega'),
                            icon: Icon(Icons.delete),
                            style: TextButton.styleFrom(
                              primary: Colors.red,
                            ),
                            onPressed: () {
                              print('Izbriši izbranega button tapped');
                              this.favIDdel();
                            }),
                      ),
                    ]
                )
            ),
          ]),
        ),
      ),
    );
  }

  Widget _getFavListItemTile(BuildContext context, int index) {

    return GestureDetector(
      //če tapkneš, ga označiš
      onTap: () {
        if (favIDs.every((item) => !item.isSelected)) {
          setState(() {
            favIDs[index].isSelected = !favIDs[index].isSelected;
          });
        }
        else
          setState(() {
            favIDs[index].isSelected= false;
          });
      },
/*      onLongPress: () {
        setState(() {
          list[index].isSelected = true;
        });
      },*/
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: favIDs[index].isSelected ?
        Colors.red[100] : Colors.white,
        child: ListTile(
          title: Text(favIDs[index].data),
        ),
      ),
    );

  }

  Widget _getListItemTile(BuildContext context, int index) {

    return GestureDetector(
      //če tapkneš, ga označiš
      onTap: () {
        if (list.every((item) => !item.isSelected)) {
          setState(() {
            list[index].isSelected = !list[index].isSelected;
          });
        }
        else
          setState(() {
            list[index].isSelected= false;
          });
      },
/*      onLongPress: () {
        setState(() {
          list[index].isSelected = true;
        });
      },*/
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: list[index].isSelected ?
          Colors.red[100] : Colors.white,
        child: ListTile(
          title: Text(list[index].data),
        ),
      ),
    );
  }

  Color getColor(String scol) {
    //red is just a sample color
    Color color;
    switch (scol) {
      case 'modri':
        color = Colors.blueAccent;
        break;
      case 'rumeni':
        color = Colors.yellow;
        break;
      case 'rjavi':
        color = Colors.brown;
        break;
      case 'zeleni':
        color = Colors.green;
        break;
      case 'rdeci':
        color = Colors.red;
        break;
      case 'crni':
        color = Colors.black;
        break;
      default:
        color = Colors.black38;
    }
    return color;
  }

  Widget LinechartWidget(int sensorno) {

    List<_LCData> LineChartData = [];

    DateFormat format = DateFormat("yyyy-MM-dd");
    LineChartData.clear();
    for (int i = 0; i < AveDataJSON[sensorno].data.length; i++) //napolni list podatkov za grafikon s podatki senzorjev
      LineChartData.add(_LCData(
          format.parse(AveDataJSON[sensorno].data[i].readingTime1),
          int.parse(AveDataJSON[sensorno].data[i].value))
      );

    return new SfCartesianChart(
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(
            maximum: 100
        ),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        tooltipBehavior: TooltipBehavior(enable: true),
        title: ChartTitle(text: 'Povprečne dnevne polnosti (%)'),
        series: <ChartSeries>[
          // Renders line chart
            LineSeries<_LCData, DateTime>(
                dataSource: LineChartData,
                color: getColor(AveDataJSON[sensorno].tip),
                name: AveDataJSON[sensorno].sensor+"-"+AveDataJSON[sensorno].tip,
                xValueMapper: (_LCData chartdata, _) => chartdata.reading_time,
                yValueMapper: (_LCData chartdata, _) => chartdata.value,
                dataLabelSettings:DataLabelSettings(isVisible : true)
            ),
           //napolni list podatkov za grafikon s podatki senzorjev
        ]
    );
  }


  Widget BarchartWidget() {

    BarChartData.clear();
    for (int i = 0; i < CurDataJSON.length; i++) { //napolni list podatkov za grafikon s podatki senzorjev
      BarChartData.add(_BCData(CurDataJSON[i]["sensor"], int.parse(CurDataJSON[i]["value1"]),CurDataJSON[i]["tip"],CurDataJSON[i]["naslov"],getColor(CurDataJSON[i]["tip"])));
    }

    return new SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
            maximum: 100
        ),
        title: ChartTitle(text: 'Polnost zabojnika (%)'),
        series: <ChartSeries>[
          ColumnSeries<_BCData, String>(
            dataSource: BarChartData,
            dataLabelSettings: DataLabelSettings(
                isVisible: true,
                useSeriesColor: true
            ),
            xValueMapper: (_BCData chartdata, _) => chartdata.sensor,
            pointColorMapper:(_BCData chartdata, _) => chartdata.segmentColor,
            yValueMapper: (_BCData chartdata, _) => chartdata.value,
            width: 0.8, // Width of the columns
            spacing: 0.2, // Spacing between the columns
          )
        ]
    );
  }

}

