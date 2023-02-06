import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as location;
import 'package:weather_app/models/meteo.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key) {
    tz.initializeTimeZones();
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class AsyncOperation<T> {
  final Completer<T> _completer = Completer<T>();

  Future<T> doOperation() => _completer.future;

  void finishOperation(T result) => _completer.complete(result);

  void errorHappened(error) => _completer.completeError(error);
}

class Lookup extends AsyncOperation<List<String>> {
  final MethodChannel _channel = const MethodChannel('weather/location');

  Lookup() {
    _channel.setMethodCallHandler(methodCallHandler);
  }

  Future<List<String>> lookup(String address) {
    _channel.invokeMethod('lookup', {'address': address});
    return doOperation().timeout(const Duration(seconds: 15), onTimeout: () => <String>[]);
  }

  // bool ready = true;
  Future<void> methodCallHandler(MethodCall methodCall) async {
    if (methodCall.method == 'response') {
      final output = (methodCall.arguments as List<dynamic>).map((e) {
        return '${e["title"]}, ${e["subtitle"]}';
      }).toList();
      finishOperation(output);
    }
  }
}

typedef AddressCallback = Function(String);

class AutocompleteAddress extends StatelessWidget {
  final AddressCallback _callback;
  const AutocompleteAddress(this.initialValue, this._callback, {super.key});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: _optionsBuilder,
      onSelected: _onSelected,
      fieldViewBuilder: _fieldViewBuilder,
    );
  }

  final String initialValue;

  Widget _fieldViewBuilder(BuildContext buildContext, TextEditingController controller, FocusNode focusNode, void Function() f) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: f,
      decoration: InputDecoration(
        hintText: "Search Somewhere",
        suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => controller.text = ""),
      ),
    );
  }

  void _onSelected(String selection) {
    debugPrint('You just selected $selection');
    _callback(selection);
  }

  Future<Iterable<String>> _optionsBuilder(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') return Future.value(<String>[]);
    return Lookup().lookup(textEditingValue.text);
  }
}

typedef LocationCallback = Function(location.LocationData, String locationName);

class ButtonBar extends StatelessWidget {
  final LocationCallback _callback;

  const ButtonBar(this._callback, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: key,
      child: const Text('Here'),
      onPressed: _onPressed,
    );
  }

  void _onPressed() async {
    debugPrint('Pressed here button');
    final loc = location.Location();

    var serviceEnabled = await loc.serviceEnabled();
    debugPrint('Service enabled?');
    if (!serviceEnabled) {
      serviceEnabled = await loc.requestService();
      if (!serviceEnabled) {
        debugPrint('Service not enabled');
        return;
      }
    }

    var permissionGranted = await loc.hasPermission();
    debugPrint('Permission granted?');
    if (permissionGranted == location.PermissionStatus.denied) {
      debugPrint('Request permission');
      permissionGranted = await loc.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) {
        debugPrint('Permission not granted: $permissionGranted');
        return;
      }
    }

    debugPrint('getLocation?');
    final locData = await loc.getLocation();
    final landmarks = await geocoding.placemarkFromCoordinates(locData.latitude!, locData.longitude!);
    debugPrint('LocationData: ${locData.latitude} ${locData.longitude} // $landmarks');
    _callback(locData, landmarks.first.locality ?? landmarks.first.name ?? 'Here');
  }
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Meteo _weather = Meteo.empty();
  String _address = "Nolensville, TN";
  // String _address = "Paris, France";

  @override
  void initState() {
    FlutterNativeTimezone.getLocalTimezone().then((value) {
      tz.setLocalLocation(tz.getLocation(value));
    });

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getWeather(_address);
  }

  Future<void> getWeather(String address) async {
    final _weatherTemp = await geocoding.locationFromAddress(address).then((locations) => MeteoApi.getWeather(locations.first));
    setState(() {
      _weather = _weatherTemp;
    });
  }

  void _onSelected(String address) {
    setState(() {
      _address = address;
    });
    getWeather(_address);
  }

  void _onLocationData(location.LocationData data, String locationName) async {
    setState(() {
      _address = locationName;
    });
    final _weatherTemp = await MeteoApi.getWeather(geocoding.Location(latitude: data.latitude!, longitude: data.longitude!, timestamp: DateTime.now()));
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
    if (_weather.nowAndAfter.isEmpty) {
      return Scaffold();
    }

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
                DismissKeyboard(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: size.height * 0.01, horizontal: size.width * 0.05),
                          child: buildNow(context, size, isDarkMode),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                          child: buildToday(context, size, isDarkMode),
                        ),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: size.height * 0.02),
                            child: buildUpcomingDays(context, size, isDarkMode)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNow(BuildContext context, Size size, bool isDarkMode) {
    // _currentTimezone ??= 'America/Chicago';
    print('buildNow for $_address');
    final autoComplete = AutocompleteAddress(_address, _onSelected);
    final today = _weather.now;
    return Wrap(children: [
      Padding(
        padding: EdgeInsets.only(top: 0, left: size.width * 0.01, right: size.width * 0.01),
        child: Align(
          child: autoComplete,
          // child: Text(
          //   _address,
          //   textAlign: TextAlign.center,
          //   style: GoogleFonts.questrial(color: Colors.black, fontSize: size.height * 0.03, fontWeight: FontWeight.normal),
          // ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: 0, left: size.width * 0.01, right: size.width * 0.01),
        child: Align(
          child: ButtonBar(_onLocationData),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(top: size.height * 0.03, left: size.width * 0.25, right: size.width * 0.25),
        child: Align(
          child: _weather.isNotEmpty
              ? Row(children: [
                  FaIcon(today.code.iconData, color: Colors.blue.shade800),
                  Text(
                    "  ${today.temp.round()}˚C",
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
                  today.code.caption,
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
                    'Feels like ${today.apparentTemp.toInt()}˚C',
                    style: GoogleFonts.questrial(color: Colors.indigo, fontSize: size.height * 0.025),
                  )
                : Container()
          ],
        ),
      ),
      Padding(
        padding: EdgeInsets.only(
          top: size.height * 0.01,
          bottom: size.height * 0.01,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _address,
              style: GoogleFonts.questrial(color: Colors.black38, fontSize: size.height * 0.02),
            )
          ],
        ),
      ),
    ]);
  }

  Widget buildTitle(BuildContext context, Size size, bool isDarkMode) {
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

  Widget buildToday(BuildContext context, Size size, bool isDarkMode) {
    final nowAndAfter = _weather.nowAndAfter.take(24).toList();
    final hours = <Condition>[];
    for (int i = 1; i < nowAndAfter.length; i += 2) {
      hours.add(Condition.merge(nowAndAfter[i], nowAndAfter[i - 1]));
      // Rework timezone to display with current timezone values
      hours.last.dateTime = hours.last.dateTime.toLocal();
    }

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

  Widget buildUpcomingDays(BuildContext context, Size size, bool isDarkMode) {
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
              child: Column(children: _weather.days.skip(1).take(7).map((w) => buildDayForecast(context, w, size, isDarkMode)).toList())),
        ],
      ),
    );
  }
}

String _hourToString(int hour) => hour <= 9 ? '0$hour' : '$hour';

Widget buildHourForecast(Condition w, Size size, bool isDarkMode) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.75, top: size.height * 0.01, bottom: size.height * 0.01),
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

Widget buildDayForecast(BuildContext context, ConditionDay w, Size size, bool isDarkMode) {
  final hourConditions = w.hourConditions;
  final hoursSummary = <Condition>[];
  for (int i = 1; i < hourConditions.length; i += 2) {
    hoursSummary.add(Condition.merge(hourConditions[i], hourConditions[i - 1]));
  }

  return ListTileTheme(
      dense: true,
      minVerticalPadding: 0,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: _dayForecastTitle(w, size, isDarkMode),
        children: hoursSummary.map((hour) => buildHourForecast(hour, size, isDarkMode)).toList(),
      ));
}

Widget _dayForecastTitle(ConditionDay w, Size size, bool isDarkMode) {
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

class DismissKeyboard extends StatelessWidget {
  final Widget child;
  const DismissKeyboard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}
