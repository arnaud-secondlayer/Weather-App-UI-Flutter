import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_app/models/meteo.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Meteo _weather = Meteo.empty();
  String cityName = "Nolensville"; //! keep it empty

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getWeather(cityName);
  }

  Future<void> getWeather(String city) async {
    final _weatherTemp = await MeteoApi.getWeather(city);
    setState(() {
      _weather = _weatherTemp;
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    print(state);
    switch (state) {
      case AppLifecycleState.resumed:
        setState(() {
          _weather = Meteo.empty();
        });
        await getWeather(cityName);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Container(
          height: size.height,
          width: size.height,
          decoration: const BoxDecoration(color: Colors.white),
          child: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding(
                      //   padding: EdgeInsets.symmetric(vertical: size.height * 0.01, horizontal: size.width * 0.05),
                      //   child: buildTitle(size, isDarkMode),
                      // ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.01, horizontal: size.width * 0.05),
                        child: buildNow(size, isDarkMode),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                        child: buildHoursForecast(size, isDarkMode),
                      ),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.02),
                          child: buildDaysForecast(size, isDarkMode)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNow(size, bool isDarkMode) {
    return Wrap(children: [
      Padding(
        padding: EdgeInsets.only(top: 0, left: size.width * 0.01, right: size.width * 0.01),
        child: Align(
          child: Text(
            cityName,
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.03, fontWeight: FontWeight.normal),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: size.height * 0.03, left: size.width * 0.25, right: size.width * 0.25),
        child: Align(
          child: _weather.isNotEmpty
              ? Row(children: [
                  FaIcon(_weather.now.iconData, color: Colors.blue.shade800),
                  Text(
                    "  ${_weather.now.temp.round()}˚C",
                    style: GoogleFonts.questrial(color: Colors.blue.shade800, fontSize: size.height * 0.08),
                  )
                ])
              : SizedBox(
                  height: size.width * 0.265,
                  width: size.width * 0.265,
                  child: Transform.scale(
                    scale: 1,
                    child: const CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(Colors.indigo)),
                  ),
                ),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.25),
        child: const Divider(color: Colors.black),
      ),
      _weather.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(top: size.height * 0.005, left: size.width * 0.01, right: size.width * 0.01),
              child: Align(
                child: Text(
                  _weather.hours.first.caption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.questrial(color: Colors.black87, fontSize: size.height * 0.03, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : Container(),
      Padding(
        padding: EdgeInsets.only(
          top: size.height * 0.01,
          bottom: size.height * 0.01,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _weather.isNotEmpty
                ? Text(
                    '${_weather.today.minTemp.toInt()}˚C',
                    style: GoogleFonts.questrial(color: Colors.indigo, fontSize: size.height * 0.03),
                  )
                : Container(),
            Text(
              '/',
              style: GoogleFonts.questrial(
                color: Colors.black54,
                fontSize: size.height * 0.03,
              ),
            ),
            _weather.isNotEmpty
                ? Text(
                    '${_weather.today.maxTemp.toInt()}˚C',
                    style: GoogleFonts.questrial(color: Colors.indigo, fontSize: size.height * 0.03),
                  )
                : Container(),
          ],
        ),
      ),
    ]);
  }

  Widget buildTitle(size, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // FaIcon(
        //   FontAwesomeIcons.bars,
        //   color: Colors.black,
        // ),
        Align(
          child: Text(
            'Clear Sky',
            style: GoogleFonts.questrial(color: const Color(0xff1D1617), fontSize: size.height * 0.02),
          ),
        ),
        // FaIcon(
        //   FontAwesomeIcons.plusCircle,
        //   color: Colors.black,
        // ),
      ],
    );
  }

  Widget buildHoursForecast(size, bool isDarkMode) {
    final now = DateTime.now();
    final hours = _weather.hours.where((w) => w.dateTime.hour > now.hour && w.dateTime.day == now.day);

    return Container(
      decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(10)), color: Colors.white.withOpacity(0.05)),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.02, left: size.width * 0.03),
              child: Text(
                'Today',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(color: Colors.black),
          Padding(padding: EdgeInsets.all(size.width * 0.00), child: Column(children: hours.map((w) => buildHourForecast(w, size, isDarkMode)).toList())),
        ],
      ),
    );
  }

  Widget buildDaysForecast(size, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(10)), color: Colors.white.withOpacity(0.05)),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.02, left: size.width * 0.03),
              child: Text(
                'Upcoming days',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(color: Colors.black),
          Padding(
              padding: EdgeInsets.all(size.width * 0.00),
              child: Column(children: _weather.days.skip(1).take(7).map((w) => buildDayForecast(w, size, isDarkMode)).toList())),
        ],
      ),
    );
  }

  Widget buildHourForecast(Condition w, size, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: size.width * 0.25),
              child: Align(alignment: Alignment.topCenter, child: FaIcon(w.iconData, color: Colors.blue.shade800)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
              child: Text(
                '${w.dateTime.hour}:00',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.01),
                child: Text(
                  '${w.temp.toInt()}˚C',
                  style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}

Widget buildDayForecast(ConditionDay w, size, bool isDarkMode) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.25),
            child: Align(alignment: Alignment.topCenter, child: FaIcon(w.iconData, color: Colors.blue.shade800)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
            child: Text(
              _weekDayString(w.date.weekday),
              style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
            ),
          ),
          Align(
            child: Padding(
              padding: EdgeInsets.only(left: size.width * 0.15, top: size.height * 0.01),
              child: Text(
                '${w.minTemp.toInt()}˚C',
                style: GoogleFonts.questrial(color: Colors.black38, fontSize: size.height * 0.025),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.01),
              child: Text(
                '${w.maxTemp.toInt()}˚C',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
              ),
            ),
          ),
        ],
      )
    ],
  );
}

String _weekDayString(int d) {
  switch (d) {
    case DateTime.monday:
      return 'MON';
    case DateTime.tuesday:
      return 'TUE';
    case DateTime.wednesday:
      return 'WED';
    case DateTime.thursday:
      return 'THU';
    case DateTime.friday:
      return 'FRI';
    case DateTime.saturday:
      return 'SAT';
    case DateTime.sunday:
      return 'SUN';
  }
  throw Exception('Unexpected day $d');
}
