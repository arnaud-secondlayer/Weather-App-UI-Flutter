// ignore_for_file: file_names
import 'package:dart_ipify/dart_ipify.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_app/models/meteo.dart';
import 'package:weather_app/models/weather2.api.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Meteo _weather = Meteo.empty();
  String cityName = ""; //! keep it empty

  int nextDayHour = 0; //! keep it 0
  int forecastResultsCount = 5; // you can change it, it's results count for forecast
  int hoursNextDay = 0; //! keep it 0
  List hoursList = []; //! keep it empty
  DateTime now = DateTime.now();
  int currTime = DateTime.now().hour; // current hour

  @override
  void initState() {
    super.initState();
    getIP();
  }

  void getIP() async {
    await Ipify.ipv4().then((value) {
      getWeather(value);
      getWeather2(value);
    });
  }

  Future<void> getWeather(String city) async {
    int j = 0;
    final _weatherTemp = await MeteoApi.getWeather(city);
    for (var i = currTime; i < 24; i++) {
      hoursList.add(i);
    }

    while (j < forecastResultsCount) {
      if (currTime >= 23) {
        hoursList.add(hoursNextDay);
        hoursNextDay++;
        currTime++;
      }
      currTime++;
      j++;
    }

    setState(() {
      _weather = _weatherTemp;
    });
  }

  Future<void> getWeather2(String city) async {
    String _cityName = await WeatherApi2.getWeather(city);

    setState(() {
      cityName = _cityName;
    });
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
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: size.height * 0.01, horizontal: size.width * 0.05),
                        child: buildTitle(size, isDarkMode),
                      ),
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
        padding: EdgeInsets.only(top: size.height * 0.03, left: size.width * 0.01, right: size.width * 0.01),
        child: Align(
          child: Text(
            cityName,
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.06, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: size.height * 0.005,
        ),
        child: Align(
          child: Text(
            'TODAY',
            style: GoogleFonts.questrial(color: Colors.black54, fontSize: size.height * 0.035),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: size.height * 0.03,
        ),
        child: Align(
          child: _weather.isNotEmpty
              ? Text(
                  "${_weather.now.temp.round()}˚C",
                  style: GoogleFonts.questrial(
                    color: _weather.now.temp.round() <= 0
                        ? Colors.blue
                        : _weather.now.temp.round() > 0 && _weather.now.temp.round() <= 15
                            ? Colors.indigo
                            : _weather.now.temp.round() > 15 && _weather.now.temp.round() < 30
                                ? Colors.deepPurple
                                : Colors.pink,
                    fontSize: size.height * 0.13,
                  ),
                )
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
        child: Divider(
          color: Colors.black,
        ),
      ),
      _weather.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(top: size.height * 0.005, left: size.width * 0.01, right: size.width * 0.01),
              child: Align(
                child: Text(
                  _weather.hours.first.caption,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.questrial(color: Colors.black54, fontSize: size.height * 0.03),
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
                    '${_weather.today.minTemp}˚C',
                    style: GoogleFonts.questrial(
                      color: _weather.today.minTemp <= 0
                          ? Colors.blue
                          : _weather.today.minTemp > 0 && _weather.today.minTemp <= 15
                              ? Colors.indigo
                              : _weather.today.minTemp > 15 && _weather.today.minTemp < 30
                                  ? Colors.deepPurple
                                  : Colors.pink,
                      fontSize: size.height * 0.03,
                    ),
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
                    '${_weather.today.maxTemp}˚C',
                    style: GoogleFonts.questrial(
                      color: _weather.today.maxTemp <= 0
                          ? Colors.blue
                          : _weather.today.maxTemp > 0 && _weather.today.maxTemp <= 15
                              ? Colors.indigo
                              : _weather.today.maxTemp > 15 && _weather.today.maxTemp < 30
                                  ? Colors.deepPurple
                                  : Colors.pink,
                      fontSize: size.height * 0.03,
                    ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        color: Colors.black.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.01, left: size.width * 0.03),
              child: Text(
                'Forecast for today',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Container(
            height: size.height * 0.36, //size.height * 0.28,
            margin: const EdgeInsets.all(20),
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: hoursList.isNotEmpty
                  ? hoursList.length <= forecastResultsCount
                      ? forecastResultsCount
                      : hoursList.length
                  : 0,
              itemBuilder: (BuildContext context, int index) {
                return _weather.isNotEmpty
                    ? buildForecastToday(
                        index == 0 ? 'Now' : "${hoursList[index]}:00",
                        _weather.hours[hoursList[index]].temp.round(),
                        _weather.hours[hoursList[index]].precipitation.round(),
                        _weather.hours[hoursList[index]].iconData,
                        size,
                        isDarkMode,
                      )
                    : Container();
              },
            ),
          ),
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
                '7-day forecast',
                style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(
            color: Colors.black,
          ),
          Padding(
              padding: EdgeInsets.all(size.width * 0.00),
              child: Column(children: _weather.days.skip(1).take(7).map((w) => buildDayForecast(w, size, isDarkMode)).toList())),
        ],
      ),
    );
  }

  Widget buildForecastToday(String time, int temp, int rainChance, IconData weatherIcon, size, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      child: Row(
        children: [
          Container(
            width: size.width * 0.1,
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.02),
            ),
          ),
          Padding(
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.005,
              ),
              child: FaIcon(weatherIcon, color: Colors.black)),
          Container(
            width: size.width * 0.25,
            child: Text(
              '$temp ˚C',
              textAlign: TextAlign.right,
              style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDayForecast(ConditionDay w, size, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: size.width * 0.25),
              child: Align(alignment: Alignment.topCenter, child: FaIcon(w.iconData, color: Colors.black)),
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
