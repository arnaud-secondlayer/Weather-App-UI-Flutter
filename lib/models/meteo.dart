import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/widgets.dart';
export 'package:font_awesome_flutter/src/fa_icon.dart';
export 'package:font_awesome_flutter/src/icon_data.dart';

// https://open-meteo.com/en
// https://api.open-meteo.com/v1/forecast?latitude=35.95&longitude=-86.67&hourly=precipitation,weathercode&timezone=auto

class Condition {
  DateTime dateTime;
  String caption;
  IconData iconData;
  double temp;
  double precipitation;

  Condition(this.dateTime, this.caption, this.temp, this.precipitation, this.iconData);
}

class ConditionDay {
  DateTime date;
  String caption;
  IconData iconData;
  double minTemp;
  double maxTemp;
  double precipitation;

  ConditionDay(this.date, this.caption, this.minTemp, this.maxTemp, this.precipitation, this.iconData);
}

class Meteo {
  // First is now
  List<Condition> hours;

  // First is today
  List<ConditionDay> days;

  Meteo({required this.hours, required this.days});

  Meteo.empty()
      : hours = [],
        days = [];

  bool get isEmpty => hours.isEmpty;
  bool get isNotEmpty => hours.isNotEmpty;

  Condition get now => hours.first;
  ConditionDay get today => days.first;
}

class MeteoApi {
  static Future<Meteo> getWeather(String city) async {
    // https://api.open-meteo.com/v1/forecast?latitude=35.95&longitude=-86.67&hourly=precipitation,weathercode&daily=timezone=auto
    // final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
    //   'latitude': '35.95',
    //   'longitude': '-86.67',
    //   'hourly': 'precipitation,weathercode,temperature_2m',
    //   'daily': 'precipitation_sum,weathercode,temperature_2m_min,temperature_2m_max',
    //   'timezone': 'auto',
    // });
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=35.95&longitude=-86.67&hourly=precipitation,weathercode,temperature_2m&daily=precipitation_sum,weathercode,temperature_2m_min,temperature_2m_max&timezone=auto');

    print(url);

    final response = await http.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      print(response.body.length);
      return _parseResponse(response.body);
    }
    return Meteo.empty();

    // return _defaultMeteo();
  }

  static Meteo _parseResponse(String response) {
    final json = jsonDecode(response);

    final daily = json['daily'];
    final daysTime = List<String>.from(daily['time']);

    final days = <ConditionDay>[];
    for (int index = 0; index < daysTime.length; index++) {
      final wmoCode = daily['weathercode'][index];
      days.add(ConditionDay(
        DateTime.parse(daysTime[index]),
        _wmoCodes[wmoCode] ?? 'Unknown',
        daily['temperature_2m_min'][index] as double,
        daily['temperature_2m_max'][index] as double,
        daily['precipitation_sum'][index] as double,
        _wmoIcons[wmoCode] ?? FontAwesomeIcons.questionCircle,
      ));
    }

    final hourly = json['hourly'];
    final hoursTime = List<String>.from(hourly['time']);
    final hours = <Condition>[];
    for (int index = 0; index < hoursTime.length; index++) {
      final wmoCode = hourly['weathercode'][index];
      hours.add(Condition(
        DateTime.parse(hoursTime[index]),
        _wmoCodes[wmoCode] ?? 'Unknown',
        hourly['temperature_2m'][index] as double,
        hourly['precipitation'][index] as double,
        _wmoIcons[wmoCode] ?? FontAwesomeIcons.questionCircle,
      ));
    }
    return Meteo(days: days, hours: hours);
  }

  static Meteo _defaultMeteo() => _parseResponse(_defaultJson);

  // static OneCallWeather _defaultWeather() {
  //   return OneCallWeather(
  //       currentWeather: OneCallCurrentWeather(
  //         iconID: "//openweathermap.org/img/wn/10d.png",
  //         mainDescription: "Clear sky",
  //         temp: 15,
  //       ),
  //       hourlyWeather: [
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //         OneCallHourlyWeather(mainDescription: 'clear', temp: 15, windSpeed: 0, precipitationChance: 22, iconID: "//openweathermap.org/img/wn/10d.png"),
  //       ]);
  // }

  // static Weather _convert(OneCallWeather weather) {
  //   final currentWeather = weather.currentWeather!;
  //   final hourlyWeather = weather.hourlyWeather!;
  //   final hour = hourlyWeather
  //       .map((w) => {
  //             'temp_c': w!.temp!.toDouble(),
  //             'wind_kph': w.windSpeed!.toDouble(),
  //             'chance_of_rain': w.precipitationChance!.toDouble(),
  //             'condition': {'icon': w.iconID, 'text': w.mainDescription}
  //           })
  //       .toList();
  //   return Weather(
  //       icon: currentWeather.iconID!,
  //       text: currentWeather.mainDescription!,
  //       maxTemp: currentWeather.temp!.toInt(),
  //       minTemp: currentWeather.temp!.toInt(),
  //       hour: hour);
  // }
  // }
}

const Map<int, String> _wmoCodes = {
  0: 'Clear',
  1: 'Mainly clear',
  2: 'Partly cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Depositing fog',
  51: 'Light drizzle',
  53: 'Moderate drizzle',
  55: 'Dense drizzle',
  56: 'Light freezing drizzle',
  57: 'Dense freezing drizzle',
  61: 'Slight rain',
  63: 'Moderate rain',
  65: 'Heavy rain',
  66: 'Light freezing rain',
  67: 'Heavy freezing rain',
  71: 'Slight snow',
  73: 'Moderate snow',
  75: 'Heavy snow',
  77: 'Snow grains',
  80: 'Slight rain showers',
  81: 'Moderate rain showers',
  82: 'Violent rain showers',
  85: 'Slight snow showers',
  86: 'Heavy snow showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with slight hail',
  99: 'Thunderstorm with heavy hail',
};

const Map<int, IconData> _wmoIcons = {
  0: FontAwesomeIcons.sun,
  1: FontAwesomeIcons.cloudSun,
  2: FontAwesomeIcons.cloud,
  3: FontAwesomeIcons.smog,
  45: FontAwesomeIcons.smog,
  48: FontAwesomeIcons.smog,
  51: FontAwesomeIcons.umbrella,
  53: FontAwesomeIcons.umbrella,
  55: FontAwesomeIcons.umbrella,
  56: FontAwesomeIcons.umbrella,
  57: FontAwesomeIcons.umbrella,
  61: FontAwesomeIcons.snowflake,
  63: FontAwesomeIcons.umbrella,
  65: FontAwesomeIcons.umbrella,
  66: FontAwesomeIcons.umbrella,
  67: FontAwesomeIcons.umbrella,
  71: FontAwesomeIcons.snowflake,
  73: FontAwesomeIcons.snowflake,
  75: FontAwesomeIcons.snowflake,
  77: FontAwesomeIcons.snowflake,
  80: FontAwesomeIcons.umbrella,
  81: FontAwesomeIcons.umbrella,
  82: FontAwesomeIcons.umbrella,
  85: FontAwesomeIcons.snowflake,
  86: FontAwesomeIcons.snowflake,
  95: FontAwesomeIcons.bolt,
  96: FontAwesomeIcons.bolt,
  99: FontAwesomeIcons.bolt,
};

const String _defaultJson = '''
{
    "latitude": 35.958027,
    "longitude": -86.65979,
    "generationtime_ms": 1.2259483337402344,
    "utc_offset_seconds": -21600,
    "timezone": "America/Chicago",
    "timezone_abbreviation": "CST",
    "elevation": 197.0,
    "hourly_units": {
        "time": "iso8601",
        "precipitation": "mm",
        "weathercode": "wmo code",
        "temperature_2m": "°C"
    },
    "hourly": {
        "time": [
            "2022-11-27T00:00",
            "2022-11-27T01:00",
            "2022-11-27T02:00",
            "2022-11-27T03:00",
            "2022-11-27T04:00",
            "2022-11-27T05:00",
            "2022-11-27T06:00",
            "2022-11-27T07:00",
            "2022-11-27T08:00",
            "2022-11-27T09:00",
            "2022-11-27T10:00",
            "2022-11-27T11:00",
            "2022-11-27T12:00",
            "2022-11-27T13:00",
            "2022-11-27T14:00",
            "2022-11-27T15:00",
            "2022-11-27T16:00",
            "2022-11-27T17:00",
            "2022-11-27T18:00",
            "2022-11-27T19:00",
            "2022-11-27T20:00",
            "2022-11-27T21:00",
            "2022-11-27T22:00",
            "2022-11-27T23:00",
            "2022-11-28T00:00",
            "2022-11-28T01:00",
            "2022-11-28T02:00",
            "2022-11-28T03:00",
            "2022-11-28T04:00",
            "2022-11-28T05:00",
            "2022-11-28T06:00",
            "2022-11-28T07:00",
            "2022-11-28T08:00",
            "2022-11-28T09:00",
            "2022-11-28T10:00",
            "2022-11-28T11:00",
            "2022-11-28T12:00",
            "2022-11-28T13:00",
            "2022-11-28T14:00",
            "2022-11-28T15:00",
            "2022-11-28T16:00",
            "2022-11-28T17:00",
            "2022-11-28T18:00",
            "2022-11-28T19:00",
            "2022-11-28T20:00",
            "2022-11-28T21:00",
            "2022-11-28T22:00",
            "2022-11-28T23:00",
            "2022-11-29T00:00",
            "2022-11-29T01:00",
            "2022-11-29T02:00",
            "2022-11-29T03:00",
            "2022-11-29T04:00",
            "2022-11-29T05:00",
            "2022-11-29T06:00",
            "2022-11-29T07:00",
            "2022-11-29T08:00",
            "2022-11-29T09:00",
            "2022-11-29T10:00",
            "2022-11-29T11:00",
            "2022-11-29T12:00",
            "2022-11-29T13:00",
            "2022-11-29T14:00",
            "2022-11-29T15:00",
            "2022-11-29T16:00",
            "2022-11-29T17:00",
            "2022-11-29T18:00",
            "2022-11-29T19:00",
            "2022-11-29T20:00",
            "2022-11-29T21:00",
            "2022-11-29T22:00",
            "2022-11-29T23:00",
            "2022-11-30T00:00",
            "2022-11-30T01:00",
            "2022-11-30T02:00",
            "2022-11-30T03:00",
            "2022-11-30T04:00",
            "2022-11-30T05:00",
            "2022-11-30T06:00",
            "2022-11-30T07:00",
            "2022-11-30T08:00",
            "2022-11-30T09:00",
            "2022-11-30T10:00",
            "2022-11-30T11:00",
            "2022-11-30T12:00",
            "2022-11-30T13:00",
            "2022-11-30T14:00",
            "2022-11-30T15:00",
            "2022-11-30T16:00",
            "2022-11-30T17:00",
            "2022-11-30T18:00",
            "2022-11-30T19:00",
            "2022-11-30T20:00",
            "2022-11-30T21:00",
            "2022-11-30T22:00",
            "2022-11-30T23:00",
            "2022-12-01T00:00",
            "2022-12-01T01:00",
            "2022-12-01T02:00",
            "2022-12-01T03:00",
            "2022-12-01T04:00",
            "2022-12-01T05:00",
            "2022-12-01T06:00",
            "2022-12-01T07:00",
            "2022-12-01T08:00",
            "2022-12-01T09:00",
            "2022-12-01T10:00",
            "2022-12-01T11:00",
            "2022-12-01T12:00",
            "2022-12-01T13:00",
            "2022-12-01T14:00",
            "2022-12-01T15:00",
            "2022-12-01T16:00",
            "2022-12-01T17:00",
            "2022-12-01T18:00",
            "2022-12-01T19:00",
            "2022-12-01T20:00",
            "2022-12-01T21:00",
            "2022-12-01T22:00",
            "2022-12-01T23:00",
            "2022-12-02T00:00",
            "2022-12-02T01:00",
            "2022-12-02T02:00",
            "2022-12-02T03:00",
            "2022-12-02T04:00",
            "2022-12-02T05:00",
            "2022-12-02T06:00",
            "2022-12-02T07:00",
            "2022-12-02T08:00",
            "2022-12-02T09:00",
            "2022-12-02T10:00",
            "2022-12-02T11:00",
            "2022-12-02T12:00",
            "2022-12-02T13:00",
            "2022-12-02T14:00",
            "2022-12-02T15:00",
            "2022-12-02T16:00",
            "2022-12-02T17:00",
            "2022-12-02T18:00",
            "2022-12-02T19:00",
            "2022-12-02T20:00",
            "2022-12-02T21:00",
            "2022-12-02T22:00",
            "2022-12-02T23:00",
            "2022-12-03T00:00",
            "2022-12-03T01:00",
            "2022-12-03T02:00",
            "2022-12-03T03:00",
            "2022-12-03T04:00",
            "2022-12-03T05:00",
            "2022-12-03T06:00",
            "2022-12-03T07:00",
            "2022-12-03T08:00",
            "2022-12-03T09:00",
            "2022-12-03T10:00",
            "2022-12-03T11:00",
            "2022-12-03T12:00",
            "2022-12-03T13:00",
            "2022-12-03T14:00",
            "2022-12-03T15:00",
            "2022-12-03T16:00",
            "2022-12-03T17:00",
            "2022-12-03T18:00",
            "2022-12-03T19:00",
            "2022-12-03T20:00",
            "2022-12-03T21:00",
            "2022-12-03T22:00",
            "2022-12-03T23:00"
        ],
        "precipitation": [
            0.10,
            0.10,
            1.60,
            0.10,
            2.00,
            0.30,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.10,
            0.20,
            0.70,
            0.10,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.10,
            0.40,
            0.40,
            1.10,
            1.40,
            0.80,
            0.70,
            1.70,
            3.50,
            1.60,
            0.80,
            0.40,
            0.60,
            0.60,
            0.10,
            0.30,
            1.40,
            1.20,
            0.20,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.00,
            0.10,
            0.10,
            0.10,
            0.10,
            0.10,
            0.10,
            2.20,
            2.20,
            2.20,
            4.00,
            4.00
        ],
        "weathercode": [
            80,
            80,
            80,
            3,
            3,
            80,
            80,
            1,
            2,
            2,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            2,
            1,
            0,
            1,
            1,
            2,
            2,
            3,
            3,
            2,
            2,
            1,
            1,
            0,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            2,
            3,
            2,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            1,
            2,
            2,
            3,
            3,
            3,
            80,
            95,
            81,
            80,
            80,
            80,
            80,
            80,
            80,
            80,
            2,
            2,
            80,
            80,
            3,
            80,
            3,
            3,
            2,
            2,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            80,
            80,
            80,
            61,
            61
        ],
        "temperature_2m": [
            14.5,
            14.5,
            15.4,
            15.5,
            15.6,
            16.4,
            14.0,
            13.5,
            12.5,
            11.8,
            11.4,
            11.6,
            11.2,
            10.7,
            10.5,
            10.2,
            9.8,
            9.7,
            9.7,
            9.6,
            9.0,
            8.7,
            8.4,
            8.2,
            7.7,
            7.2,
            7.7,
            8.1,
            8.2,
            8.2,
            8.2,
            8.2,
            8.5,
            8.8,
            9.3,
            9.1,
            9.5,
            9.2,
            9.5,
            10.1,
            9.3,
            8.9,
            8.9,
            8.9,
            8.8,
            8.8,
            7.7,
            8.0,
            7.6,
            7.8,
            6.6,
            6.0,
            6.0,
            6.2,
            6.4,
            7.9,
            9.5,
            11.6,
            13.8,
            15.5,
            16.9,
            17.5,
            17.4,
            16.9,
            16.2,
            15.2,
            15.0,
            14.7,
            14.5,
            14.5,
            14.5,
            14.5,
            14.7,
            15.2,
            15.4,
            15.7,
            15.9,
            16.0,
            16.8,
            17.0,
            17.2,
            8.4,
            6.2,
            4.9,
            6.2,
            6.7,
            7.1,
            6.9,
            6.0,
            4.7,
            4.0,
            3.4,
            2.8,
            2.4,
            2.0,
            1.7,
            1.4,
            1.1,
            0.8,
            0.5,
            0.2,
            -0.1,
            -0.3,
            -0.3,
            1.1,
            2.6,
            4.1,
            5.6,
            6.8,
            7.6,
            7.9,
            7.8,
            6.6,
            5.4,
            5.1,
            4.8,
            4.1,
            3.7,
            4.4,
            4.4,
            4.3,
            4.2,
            4.0,
            3.8,
            3.6,
            3.4,
            3.7,
            4.7,
            6.0,
            7.9,
            9.4,
            10.9,
            12.4,
            12.7,
            12.6,
            12.3,
            12.0,
            11.6,
            11.3,
            11.5,
            11.8,
            12.4,
            12.7,
            13.0,
            13.3,
            13.4,
            13.5,
            13.6,
            13.6,
            13.6,
            13.6,
            13.8,
            14.1,
            14.5,
            14.9,
            15.4,
            15.8,
            15.9,
            15.8,
            15.8,
            16.0,
            16.4,
            16.7,
            16.7,
            16.4,
            16.1,
            15.8,
            15.6
        ]
    },
    "daily_units": {
        "time": "iso8601",
        "precipitation_sum": "mm",
        "weathercode": "wmo code",
        "temperature_2m_min": "°C",
        "temperature_2m_max": "°C"
    },
    "daily": {
        "time": [
            "2022-11-27",
            "2022-11-28",
            "2022-11-29",
            "2022-11-30",
            "2022-12-01",
            "2022-12-02",
            "2022-12-03"
        ],
        "precipitation_sum": [
            5.30,
            0.00,
            6.60,
            10.70,
            0.00,
            0.00,
            15.20
        ],
        "weathercode": [
            80,
            3,
            95,
            80,
            3,
            3,
            80
        ],
        "temperature_2m_min": [
            8.2,
            7.2,
            6.0,
            1.7,
            -0.3,
            3.4,
            13.3
        ],
        "temperature_2m_max": [
            16.4,
            10.1,
            17.5,
            17.2,
            7.9,
            13.0,
            16.7
        ]
    }
}
''';
