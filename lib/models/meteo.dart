import 'dart:convert';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/widgets.dart';
export 'package:font_awesome_flutter/src/fa_icon.dart';
export 'package:font_awesome_flutter/src/icon_data.dart';

// https://open-meteo.com/en
// https://api.open-meteo.com/v1/forecast?latitude=35.95&longitude=-86.67&hourly=precipitation,weathercode&timezone=auto

// From https://www.weather.gov/media/documentation/docs/NWS_Geolocation.pdf
// Alerts: curl "https://api.weather.gov/alerts/active?point=35.9522,-86.6694"
// {
//     "@context": [
//         "https://geojson.org/geojson-ld/geojson-context.jsonld",
//         {
//             "@version": "1.1",
//             "wx": "https://api.weather.gov/ontology#",
//             "@vocab": "https://api.weather.gov/ontology#"
//         }
//     ],
//     "type": "FeatureCollection",
//     "features": [
//         {
//             "id": "https://api.weather.gov/alerts/urn:oid:2.49.0.1.840.0.c66b7901a6c24875d1fef592b84a13b5dbf9c2bb.001.1",
//             "type": "Feature",
//             "geometry": null,
//             "properties": {
//                 "@id": "https://api.weather.gov/alerts/urn:oid:2.49.0.1.840.0.c66b7901a6c24875d1fef592b84a13b5dbf9c2bb.001.1",
//                 "@type": "wx:Alert",
//                 "id": "urn:oid:2.49.0.1.840.0.c66b7901a6c24875d1fef592b84a13b5dbf9c2bb.001.1",
//                 "areaDesc": "Davidson, TN; Sumner, TN; Williamson, TN",
//                 "geocode": {
//                     "SAME": [
//                         "047037",
//                         "047165",
//                         "047187"
//                     ],
//                     "UGC": [
//                         "TNC037",
//                         "TNC165",
//                         "TNC187"
//                     ]
//                 },
//                 "affectedZones": [
//                     "https://api.weather.gov/zones/county/TNC037",
//                     "https://api.weather.gov/zones/county/TNC165",
//                     "https://api.weather.gov/zones/county/TNC187"
//                 ],
//                 "references": [],
//                 "sent": "2023-01-03T05:40:00-06:00",
//                 "effective": "2023-01-03T05:40:00-06:00",
//                 "onset": "2023-01-03T05:40:00-06:00",
//                 "expires": "2023-01-03T11:00:00-06:00",
//                 "ends": "2023-01-03T11:00:00-06:00",
//                 "status": "Actual",
//                 "messageType": "Alert",
//                 "category": "Met",
//                 "severity": "Extreme",
//                 "certainty": "Possible",
//                 "urgency": "Future",
//                 "event": "Tornado Watch",
//                 "sender": "w-nws.webmaster@noaa.gov",
//                 "senderName": "NWS Nashville TN",
//                 "headline": "Tornado Watch issued January 3 at 5:40AM CST until January 3 at 11:00AM CST by NWS Nashville TN",
//                 "description": "THE NATIONAL WEATHER SERVICE HAS EXTENDED TORNADO WATCH 6 TO\nINCLUDE THE FOLLOWING AREAS UNTIL 11 AM CST THIS MORNING\n\nIN TENNESSEE THIS WATCH INCLUDES 3 COUNTIES\n\nIN MIDDLE TENNESSEE\n\nDAVIDSON              SUMNER                WILLIAMSON\n\nTHIS INCLUDES THE CITIES OF BRENTWOOD, FRANKLIN, GALLATIN,\nGOODLETTSVILLE, HENDERSONVILLE, AND NASHVILLE.",
//                 "instruction": null,
//                 "response": "Monitor",
//                 "parameters": {
//                     "AWIPSidentifier": [
//                         "WCNOHX"
//                     ],
//                     "WMOidentifier": [
//                         "WWUS64 KOHX 031140"
//                     ],
//                     "BLOCKCHANNEL": [
//                         "EAS",
//                         "NWEM",
//                         "CMAS"
//                     ],
//                     "EAS-ORG": [
//                         "WXR"
//                     ],
//                     "VTEC": [
//                         "/O.EXA.KOHX.TO.A.0006.000000T0000Z-230103T1700Z/"
//                     ],
//                     "eventEndingTime": [
//                         "2023-01-03T17:00:00+00:00"
//                     ]
//                 }
//             }
//         }
//     ],
//     "title": "current watches, warnings, and advisories for 35.9522 N, 86.6694 W",
//     "updated": "2023-01-03T11:43:34+00:00"
// }

enum WmoCode {
  clear(0, 'Clear', FontAwesomeIcons.sun),
  mainlyClear(1, 'Mainly clear', FontAwesomeIcons.cloudSun),
  partlyCloudy(2, 'Partly cloudy', FontAwesomeIcons.cloud),
  overcast(3, 'Overcast', FontAwesomeIcons.cloud),
  fog(45, 'Fog', FontAwesomeIcons.smog),
  depositingFog(48, 'Depositing fog', FontAwesomeIcons.smog),
  lightDrizzle(51, 'Light drizzle', FontAwesomeIcons.cloudSunRain),
  moderateDrizzle(53, 'Moderate drizzle', FontAwesomeIcons.cloudSunRain),
  denseDrizzle(55, 'Dense drizzle', FontAwesomeIcons.cloudSunRain),
  lightFreezingDrizzle(56, 'Light freezing drizzle', FontAwesomeIcons.cloudSunRain),
  denseFreezingDrizzle(57, 'Dense freezing drizzle', FontAwesomeIcons.cloudSunRain),
  slightRain(61, 'Slight rain', FontAwesomeIcons.umbrella),
  moderateRain(63, 'Moderate rain', FontAwesomeIcons.umbrella),
  heavyRain(65, 'Heavy rain', FontAwesomeIcons.umbrella),
  lightFreezingRain(66, 'Light freezing rain', FontAwesomeIcons.umbrella),
  heavyFreezingRain(67, 'Heavy freezing rain', FontAwesomeIcons.umbrella),
  slightSnow(71, 'Slight snow', FontAwesomeIcons.snowflake),
  moderateSnow(73, 'Moderate snow', FontAwesomeIcons.snowflake),
  heavySnow(75, 'Heavy snow', FontAwesomeIcons.snowflake),
  snowGrains(77, 'Snow grains', FontAwesomeIcons.snowflake),
  slightRainShowers(80, 'Slight rain showers', FontAwesomeIcons.umbrella),
  moderateRainShowers(81, 'Moderate rain showers', FontAwesomeIcons.umbrella),
  violentRainShowers(82, 'Violent rain showers', FontAwesomeIcons.umbrella),
  slightSnowShowers(85, 'Slight snow showers', FontAwesomeIcons.snowflake),
  heavySnowShowers(86, 'Heavy snow showers', FontAwesomeIcons.snowflake),
  thunderstorm(95, 'Thunderstorm', FontAwesomeIcons.bolt),
  thunderstormWithSlightHail(96, 'Thunderstorm with slight hail', FontAwesomeIcons.bolt),
  thunderstormWithHeavyHail(99, 'Thunderstorm with heavy hail', FontAwesomeIcons.bolt);

  const WmoCode(this.code, this.caption, this.iconData);
  final int code;
  final String caption;
  final IconData iconData;
}

class Condition {
  DateTime dateTime;
  WmoCode code;
  double temp;
  double apparentTemp;
  double precipitation;

  Condition(this.dateTime, this.code, this.temp, this.apparentTemp, this.precipitation);

  Condition.merge(Condition c0, Condition c1)
      : dateTime = c0.dateTime.millisecondsSinceEpoch < c1.dateTime.millisecondsSinceEpoch ? c0.dateTime : c1.dateTime,
        code = c0.code.code > c1.code.code ? c0.code : c1.code,
        temp = (c0.temp + c1.temp) / 2,
        apparentTemp = (c0.apparentTemp + c1.apparentTemp) / 2,
        precipitation = max(c0.precipitation, c1.precipitation);
}

class ConditionDay {
  DateTime date;
  WmoCode code;
  double minTemp;
  double maxTemp;
  double precipitation;
  List<Condition> hourConditions;

  ConditionDay(this.date, this.code, this.minTemp, this.maxTemp, this.precipitation, this.hourConditions);
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

  Condition get now => nowAndAfter.first;

  List<Condition> get nowAndAfter {
    final now = tz.TZDateTime.now(tz.local);
    return hours.where((element) => element.dateTime.isAfter(now)).toList();
  }
}

class MeteoApi {
  static Future<Meteo> getWeather(Location loc) async {
    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${loc.latitude}&longitude=${loc.longitude}&hourly=precipitation,weathercode,temperature_2m,apparent_temperature&daily=precipitation_sum,weathercode,temperature_2m_min,temperature_2m_max&timezone=auto');

    final response = await http.get(url);
    return response.statusCode == 200 ? _parseResponse(response.body) : Meteo.empty();

    // return _defaultMeteo();
  }

  static Meteo _parseResponse(String response) {
    final json = jsonDecode(response);

    final daily = json['daily'];
    final daysTime = List<String>.from(daily['time']);

    final timezone = json['timezone'] as String;
    final responseLocation = tz.getLocation(timezone);

    final hourly = json['hourly'];
    final hoursTime = List<String>.from(hourly['time']);

    final hours = <Condition>[];
    for (int index = 0; index < hoursTime.length; index++) {
      final wmoCode = WmoCode.values.firstWhere((element) => element.code == hourly['weathercode'][index]);
      hours.add(Condition(
        _parseResponseDateTime(hoursTime[index], responseLocation),
        wmoCode,
        hourly['temperature_2m'][index] as double,
        hourly['apparent_temperature'][index] as double,
        hourly['precipitation'][index] as double,
      ));
    }

    final days = <ConditionDay>[];
    for (int index = 0; index < daysTime.length; index++) {
      final wmoCode = WmoCode.values.firstWhere((element) => element.code == daily['weathercode'][index]);
      final day = DateTime.parse(daysTime[index]);
      final dayHourIndices = List.generate(hoursTime.length, (index) => index).where((index) => DateTime.parse(hoursTime[index]).day == day.day).toList();
      final dayHourConditions = dayHourIndices
          .map((index) => Condition(
                // DateTime.parse(hoursTime[index]),
                _parseResponseDateTime(hoursTime[index], responseLocation),
                WmoCode.values.firstWhere((element) => element.code == hourly['weathercode'][index]),
                hourly['temperature_2m'][index] as double,
                hourly['apparent_temperature'][index] as double,
                hourly['precipitation'][index] as double,
              ))
          .toList();
      days.add(ConditionDay(day, wmoCode, daily['temperature_2m_min'][index] as double, daily['temperature_2m_max'][index] as double,
          daily['precipitation_sum'][index] as double, dayHourConditions));
    }

    return Meteo(days: days, hours: hours);
  }

  static Meteo _defaultMeteo() => _parseResponse(_defaultJson);
}

tz.TZDateTime _parseResponseDateTime(String responseDateTimeString, tz.Location responseLocation) {
  final parsedDateTime = DateTime.parse(responseDateTimeString);
  return tz.TZDateTime(
      responseLocation, parsedDateTime.year, parsedDateTime.month, parsedDateTime.day, parsedDateTime.hour, parsedDateTime.minute, parsedDateTime.second);
}

// const Map<int, String> _wmoCodes = {
//   0: 'Clear',
//   1: 'Mainly clear',
//   2: 'Partly cloudy',
//   3: 'Overcast',
//   45: 'Fog',
//   48: 'Depositing fog',
//   51: 'Light drizzle',
//   53: 'Moderate drizzle',
//   55: 'Dense drizzle',
//   56: 'Light freezing drizzle',
//   57: 'Dense freezing drizzle',
//   61: 'Slight rain',
//   63: 'Moderate rain',
//   65: 'Heavy rain',
//   66: 'Light freezing rain',
//   67: 'Heavy freezing rain',
//   71: 'Slight snow',
//   73: 'Moderate snow',
//   75: 'Heavy snow',
//   77: 'Snow grains',
//   80: 'Slight rain showers',
//   81: 'Moderate rain showers',
//   82: 'Violent rain showers',
//   85: 'Slight snow showers',
//   86: 'Heavy snow showers',
//   95: 'Thunderstorm',
//   96: 'Thunderstorm with slight hail',
//   99: 'Thunderstorm with heavy hail',
// };

// const Map<int, IconData> _wmoIcons = {
//   0: FontAwesomeIcons.sun,
//   1: FontAwesomeIcons.cloudSun,
//   2: FontAwesomeIcons.cloud,
//   3: FontAwesomeIcons.smog,
//   45: FontAwesomeIcons.smog,
//   48: FontAwesomeIcons.smog,
//   51: FontAwesomeIcons.umbrella,
//   53: FontAwesomeIcons.umbrella,
//   55: FontAwesomeIcons.umbrella,
//   56: FontAwesomeIcons.umbrella,
//   57: FontAwesomeIcons.umbrella,
//   61: FontAwesomeIcons.umbrella,
//   63: FontAwesomeIcons.umbrella,
//   65: FontAwesomeIcons.umbrella,
//   66: FontAwesomeIcons.umbrella,
//   67: FontAwesomeIcons.umbrella,
//   71: FontAwesomeIcons.snowflake,
//   73: FontAwesomeIcons.snowflake,
//   75: FontAwesomeIcons.snowflake,
//   77: FontAwesomeIcons.snowflake,
//   80: FontAwesomeIcons.umbrella,
//   81: FontAwesomeIcons.umbrella,
//   82: FontAwesomeIcons.umbrella,
//   85: FontAwesomeIcons.snowflake,
//   86: FontAwesomeIcons.snowflake,
//   95: FontAwesomeIcons.bolt,
//   96: FontAwesomeIcons.bolt,
//   99: FontAwesomeIcons.bolt,
// };

const String _defaultJson = '''
{
    "latitude": 37.75607,
    "longitude": -122.44577,
    "generationtime_ms": 1.1899471282958984,
    "utc_offset_seconds": -28800,
    "timezone": "America/Los_Angeles",
    "timezone_abbreviation": "PST",
    "elevation": 88.0,
    "hourly_units": {
        "time": "iso8601",
        "precipitation": "mm",
        "weathercode": "wmo code",
        "temperature_2m": "°C"
    },
    "hourly": {
        "time": [
            "2023-01-02T00:00",
            "2023-01-02T01:00",
            "2023-01-02T02:00",
            "2023-01-02T03:00",
            "2023-01-02T04:00",
            "2023-01-02T05:00",
            "2023-01-02T06:00",
            "2023-01-02T07:00",
            "2023-01-02T08:00",
            "2023-01-02T09:00",
            "2023-01-02T10:00",
            "2023-01-02T11:00",
            "2023-01-02T12:00",
            "2023-01-02T13:00",
            "2023-01-02T14:00",
            "2023-01-02T15:00",
            "2023-01-02T16:00",
            "2023-01-02T17:00",
            "2023-01-02T18:00",
            "2023-01-02T19:00",
            "2023-01-02T20:00",
            "2023-01-02T21:00",
            "2023-01-02T22:00",
            "2023-01-02T23:00",
            "2023-01-03T00:00",
            "2023-01-03T01:00",
            "2023-01-03T02:00",
            "2023-01-03T03:00",
            "2023-01-03T04:00",
            "2023-01-03T05:00",
            "2023-01-03T06:00",
            "2023-01-03T07:00",
            "2023-01-03T08:00",
            "2023-01-03T09:00",
            "2023-01-03T10:00",
            "2023-01-03T11:00",
            "2023-01-03T12:00",
            "2023-01-03T13:00",
            "2023-01-03T14:00",
            "2023-01-03T15:00",
            "2023-01-03T16:00",
            "2023-01-03T17:00",
            "2023-01-03T18:00",
            "2023-01-03T19:00",
            "2023-01-03T20:00",
            "2023-01-03T21:00",
            "2023-01-03T22:00",
            "2023-01-03T23:00",
            "2023-01-04T00:00",
            "2023-01-04T01:00",
            "2023-01-04T02:00",
            "2023-01-04T03:00",
            "2023-01-04T04:00",
            "2023-01-04T05:00",
            "2023-01-04T06:00",
            "2023-01-04T07:00",
            "2023-01-04T08:00",
            "2023-01-04T09:00",
            "2023-01-04T10:00",
            "2023-01-04T11:00",
            "2023-01-04T12:00",
            "2023-01-04T13:00",
            "2023-01-04T14:00",
            "2023-01-04T15:00",
            "2023-01-04T16:00",
            "2023-01-04T17:00",
            "2023-01-04T18:00",
            "2023-01-04T19:00",
            "2023-01-04T20:00",
            "2023-01-04T21:00",
            "2023-01-04T22:00",
            "2023-01-04T23:00",
            "2023-01-05T00:00",
            "2023-01-05T01:00",
            "2023-01-05T02:00",
            "2023-01-05T03:00",
            "2023-01-05T04:00",
            "2023-01-05T05:00",
            "2023-01-05T06:00",
            "2023-01-05T07:00",
            "2023-01-05T08:00",
            "2023-01-05T09:00",
            "2023-01-05T10:00",
            "2023-01-05T11:00",
            "2023-01-05T12:00",
            "2023-01-05T13:00",
            "2023-01-05T14:00",
            "2023-01-05T15:00",
            "2023-01-05T16:00",
            "2023-01-05T17:00",
            "2023-01-05T18:00",
            "2023-01-05T19:00",
            "2023-01-05T20:00",
            "2023-01-05T21:00",
            "2023-01-05T22:00",
            "2023-01-05T23:00",
            "2023-01-06T00:00",
            "2023-01-06T01:00",
            "2023-01-06T02:00",
            "2023-01-06T03:00",
            "2023-01-06T04:00",
            "2023-01-06T05:00",
            "2023-01-06T06:00",
            "2023-01-06T07:00",
            "2023-01-06T08:00",
            "2023-01-06T09:00",
            "2023-01-06T10:00",
            "2023-01-06T11:00",
            "2023-01-06T12:00",
            "2023-01-06T13:00",
            "2023-01-06T14:00",
            "2023-01-06T15:00",
            "2023-01-06T16:00",
            "2023-01-06T17:00",
            "2023-01-06T18:00",
            "2023-01-06T19:00",
            "2023-01-06T20:00",
            "2023-01-06T21:00",
            "2023-01-06T22:00",
            "2023-01-06T23:00",
            "2023-01-07T00:00",
            "2023-01-07T01:00",
            "2023-01-07T02:00",
            "2023-01-07T03:00",
            "2023-01-07T04:00",
            "2023-01-07T05:00",
            "2023-01-07T06:00",
            "2023-01-07T07:00",
            "2023-01-07T08:00",
            "2023-01-07T09:00",
            "2023-01-07T10:00",
            "2023-01-07T11:00",
            "2023-01-07T12:00",
            "2023-01-07T13:00",
            "2023-01-07T14:00",
            "2023-01-07T15:00",
            "2023-01-07T16:00",
            "2023-01-07T17:00",
            "2023-01-07T18:00",
            "2023-01-07T19:00",
            "2023-01-07T20:00",
            "2023-01-07T21:00",
            "2023-01-07T22:00",
            "2023-01-07T23:00",
            "2023-01-08T00:00",
            "2023-01-08T01:00",
            "2023-01-08T02:00",
            "2023-01-08T03:00",
            "2023-01-08T04:00",
            "2023-01-08T05:00",
            "2023-01-08T06:00",
            "2023-01-08T07:00",
            "2023-01-08T08:00",
            "2023-01-08T09:00",
            "2023-01-08T10:00",
            "2023-01-08T11:00",
            "2023-01-08T12:00",
            "2023-01-08T13:00",
            "2023-01-08T14:00",
            "2023-01-08T15:00",
            "2023-01-08T16:00",
            "2023-01-08T17:00",
            "2023-01-08T18:00",
            "2023-01-08T19:00",
            "2023-01-08T20:00",
            "2023-01-08T21:00",
            "2023-01-08T22:00",
            "2023-01-08T23:00"
        ],
        "precipitation": [
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
            0.30,
            0.80,
            3.00,
            4.70,
            5.90,
            1.50,
            0.40,
            0.00,
            0.00,
            0.00,
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
            0.10,
            1.00,
            2.00,
            3.10,
            2.70,
            4.10,
            0.40,
            0.10,
            0.10,
            0.10,
            0.20,
            0.10,
            5.90,
            4.40,
            7.80,
            1.50,
            3.50,
            5.80,
            2.60,
            0.60,
            1.10,
            0.60,
            0.30,
            0.10,
            0.00,
            0.10,
            0.30,
            1.70,
            2.60,
            2.30,
            1.70,
            2.60,
            2.80,
            1.80,
            1.20,
            0.70,
            0.50,
            0.30,
            0.20,
            0.10,
            0.20,
            0.10,
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
            1.60,
            1.60,
            1.60,
            0.40,
            0.40,
            0.40,
            0.10,
            0.10,
            0.10,
            0.00,
            0.00,
            0.00,
            0.80,
            0.80,
            0.80,
            2.10,
            2.10,
            2.10,
            3.50,
            3.50,
            3.50,
            5.90,
            5.90,
            5.90,
            2.60,
            2.60,
            2.60,
            2.60,
            2.60,
            2.60,
            3.00,
            3.00,
            3.00,
            3.60,
            3.60,
            3.60,
            3.70
        ],
        "weathercode": [
            1,
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
            51,
            51,
            51,
            51,
            53,
            63,
            63,
            63,
            61,
            51,
            3,
            3,
            3,
            51,
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
            0,
            0,
            0,
            1,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            51,
            53,
            61,
            63,
            63,
            63,
            51,
            51,
            51,
            51,
            51,
            51,
            63,
            81,
            81,
            80,
            81,
            81,
            81,
            53,
            53,
            53,
            51,
            51,
            3,
            51,
            51,
            80,
            81,
            80,
            80,
            81,
            81,
            80,
            53,
            53,
            53,
            51,
            51,
            51,
            51,
            51,
            51,
            0,
            0,
            0,
            0,
            1,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            1,
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
            61,
            61,
            61,
            51,
            51,
            51,
            51,
            51,
            51,
            3,
            3,
            3,
            53,
            53,
            53,
            80,
            80,
            80,
            63,
            63,
            63,
            81,
            81,
            81,
            81,
            81,
            81,
            63,
            63,
            63,
            63,
            63,
            63,
            63,
            63,
            63,
            63
        ],
        "temperature_2m": [
            7.5,
            7.6,
            7.3,
            6.5,
            6.6,
            6.1,
            5.9,
            6.1,
            6.0,
            7.1,
            7.5,
            8.1,
            8.8,
            8.0,
            8.6,
            8.0,
            8.0,
            7.7,
            7.7,
            7.6,
            7.5,
            8.0,
            8.1,
            8.1,
            7.8,
            7.6,
            7.3,
            6.8,
            7.1,
            7.2,
            7.3,
            7.3,
            7.5,
            8.2,
            10.5,
            11.3,
            11.0,
            10.8,
            10.8,
            10.7,
            10.5,
            9.2,
            8.3,
            7.9,
            7.7,
            7.7,
            7.5,
            7.3,
            7.2,
            7.3,
            7.2,
            6.9,
            7.4,
            8.5,
            9.5,
            10.0,
            10.4,
            10.8,
            11.3,
            11.2,
            11.9,
            13.4,
            13.4,
            13.5,
            13.6,
            12.9,
            12.6,
            12.9,
            13.1,
            13.1,
            12.5,
            13.2,
            13.0,
            13.2,
            12.9,
            12.4,
            12.0,
            11.7,
            11.6,
            11.5,
            11.1,
            10.9,
            11.1,
            11.2,
            10.9,
            10.6,
            10.4,
            10.4,
            10.4,
            10.4,
            10.5,
            10.6,
            10.0,
            9.7,
            9.5,
            9.5,
            9.1,
            8.8,
            8.6,
            8.5,
            8.3,
            8.2,
            8.2,
            8.4,
            8.4,
            9.2,
            9.9,
            11.6,
            13.2,
            13.6,
            13.8,
            13.8,
            13.2,
            12.5,
            12.0,
            11.6,
            11.3,
            11.1,
            10.8,
            10.5,
            10.2,
            10.1,
            10.1,
            10.4,
            10.6,
            10.7,
            10.6,
            10.7,
            11.3,
            12.0,
            12.7,
            12.4,
            11.7,
            11.0,
            10.9,
            10.9,
            11.0,
            11.1,
            11.1,
            11.3,
            11.5,
            11.7,
            11.9,
            11.9,
            11.7,
            11.5,
            11.2,
            10.9,
            10.7,
            10.7,
            10.8,
            11.0,
            11.2,
            11.5,
            11.8,
            11.8,
            11.7,
            11.6,
            11.5,
            11.5,
            11.3,
            11.0,
            10.8,
            10.5,
            10.3,
            10.2,
            10.3,
            10.7
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
            "2023-01-02",
            "2023-01-03",
            "2023-01-04",
            "2023-01-05",
            "2023-01-06",
            "2023-01-07",
            "2023-01-08"
        ],
        "precipitation_sum": [
            16.90,
            0.10,
            45.50,
            22.00,
            0.00,
            7.10,
            75.20
        ],
        "weathercode": [
            63,
            51,
            81,
            81,
            3,
            61,
            81
        ],
        "temperature_2m_min": [
            5.9,
            6.8,
            6.9,
            9.5,
            8.2,
            10.1,
            10.2
        ],
        "temperature_2m_max": [
            8.8,
            11.3,
            13.6,
            13.2,
            13.8,
            12.7,
            11.8
        ]
    }
}
''';
