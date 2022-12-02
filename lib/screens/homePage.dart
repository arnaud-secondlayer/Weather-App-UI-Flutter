import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_app/models/meteo.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class AutocompleteAddress extends StatelessWidget {
  final String initialValue;
  const AutocompleteAddress(this.initialValue, {super.key});

  static const List<String> _kOptions = <String>[
    'aardvark',
    'bobcat',
    'chameleon',
  ];

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return _kOptions.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Meteo _weather = Meteo.empty();
  final String _address = "246 Norfolk Ln, Nolensville"; //! keep it empty

  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getWeather(_address);
  }

  Future<void> getWeather(String address) async {
    final _weatherTemp = await locationFromAddress(address).then((locations) => MeteoApi.getWeather(locations.first));
    setState(() {
      _weather = _weatherTemp;
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await getWeather(_address);
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
          // child: AutocompleteAddress(_address),
          child: Text(
            _address,
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
                  FaIcon(_weather.now.code.iconData, color: Colors.blue.shade800),
                  Text(
                    "  ${_weather.now.temp.round()}˚C",
                    style: GoogleFonts.questrial(color: Colors.blue.shade800, fontSize: size.height * 0.07),
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
                  _weather.now.code.caption,
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
    // TODO: we should summarize, not skip
    final hours = _weather.hours.where((w) => w.dateTime.hour % 2 == 0 && (w.dateTime.hour >= now.hour || w.dateTime.day > now.day)).take(12);

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

  static String _hourToString(int hour) => hour <= 9 ? '0$hour' : '$hour';

  Widget buildHourForecast(Condition w, size, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(right: size.width * 0.77, top: size.height * 0.01, bottom: size.height * 0.01),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text('${_hourToString(w.dateTime.hour)}:00', style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025)),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: size.width * 0.25),
              child: Align(alignment: Alignment.topCenter, child: FaIcon(w.code.iconData, color: Colors.blue.shade800)),
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
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02, vertical: size.height * 0.01),
            child: Text(
              _weekDayString(w.date.weekday),
              style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.025),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.25),
            child: Align(alignment: Alignment.topCenter, child: FaIcon(w.code.iconData, color: Colors.blue.shade800)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: size.width * 0.3, top: size.height * 0.01),
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
