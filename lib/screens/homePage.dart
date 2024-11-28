import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as location;
import 'package:weather_app/models/meteo.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key}) {
    tz.initializeTimeZones();
  }

  @override
  HomePageState createState() => HomePageState();
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
  const AutocompleteAddress(this._callback, {super.key});

  @override
  Widget build(BuildContext context) => Autocomplete<String>(
        initialValue: const TextEditingValue(),
        optionsBuilder: _optionsBuilder,
        onSelected: _callback,
        fieldViewBuilder: _fieldViewBuilder,
      );

  Widget _fieldViewBuilder(BuildContext buildContext, TextEditingController controller, FocusNode focusNode, void Function() f) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: f,
      decoration: InputDecoration(
        hintText: "Search for a location",
        suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => controller.text = ""),
      ),
    );
  }

  Future<Iterable<String>> _optionsBuilder(TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') return Future.value(<String>[]);
    return Lookup().lookup(textEditingValue.text);
  }
}

typedef LocationCallback = Function(geocoding.Location, String locationName);

class ButtonBar extends StatelessWidget {
  final LocationCallback _callback;
  final List<String> _locations;
  final AutocompleteAddress _autocompleteAddress;
  final Size _size;

  const ButtonBar(this._size, this._autocompleteAddress, this._locations, this._callback, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [_iconButton(FontAwesomeIcons.locationArrow, onPressed: _onPressedHere), ...history],
          ),
          children: [_autocompleteAddress.build(context)],
        ));
  }

  IconButton _iconButton(IconData icon, {required void Function() onPressed}) {
    return IconButton(
      key: key,
      icon: Icon(icon, color: Colors.blue.shade800, size: _size.width * 0.035),
      onPressed: onPressed,
    );
  }

  TextButton _textButton(String caption, {required void Function() onPressed}) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        maximumSize: Size(_size.width * 0.22, double.infinity),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        caption,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }

  Iterable<Widget> get history {
    return _locations.map((locationString) => _textButton(
          locationToCaption(locationString),
          onPressed: () => _onPressedLocation(locationString),
        ));
  }

  static String locationToCaption(String locationString) {
    var index = locationString.indexOf(RegExp(r'(,)'));
    if (index == -1) index = locationString.length;
    return locationString.substring(0, index);
  }

  void _onPressedLocation(String address) async {
    return geocoding.locationFromAddress(address).then((locations) => _callback(locations.first, address));
  }

  void _onPressedHere() async {
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

    final geoLocation = await geocoding.Location(latitude: locData.latitude!, longitude: locData.longitude!, timestamp: DateTime.now());
    _callback(geoLocation, landmarks.first.locality ?? landmarks.first.name ?? 'Here');
  }
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Meteo _weather = Meteo.empty();
  String _address = 'Nolensville, TN';
  final List<String> _history = [
    'Nolensville, TN',
    'Paris, France',
    'New York, USA',
  ];
  // String _address = "Paris, France";

  @override
  void initState() {
    FlutterNativeTimezone.getLocalTimezone().then((value) {
      tz.setLocalLocation(tz.getLocation(value));
    });

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateWeatherFromAddress(_address);
  }

  Future<void> _updateWeatherFromAddress(String address) async {
    final locations = await geocoding.locationFromAddress(address);
    _updateWeather(locations.first, address);
  }

  void _updateHistory(String locationName) {
    final alreadyInList = _history.indexWhere((element) => element == locationName);
    if (alreadyInList == -1) {
      _history.removeLast();
    } else {
      _history.removeAt(alreadyInList);
    }
    _history.insert(0, locationName);
  }

  Future<void> _updateWeather(geocoding.Location location, String locationName) async {
    setState(() {
      _address = locationName;
      _updateHistory(locationName);
    });
    final weatherTemp = await MeteoApi.getWeather(location);
    setState(() {
      _weather = weatherTemp;
    });
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        await _updateWeatherFromAddress(_address);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_weather.nowAndAfter.isEmpty) {
      return const Scaffold();
    }

    final size = MediaQuery.of(context).size;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
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
    final autoComplete = AutocompleteAddress(_updateWeatherFromAddress);
    final today = _weather.now;
    return Wrap(children: [
      Padding(
        padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
        child: Align(
          child: ButtonBar(size, autoComplete, _history, _updateWeather),
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
  const DismissKeyboard({super.key, required this.child});

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
