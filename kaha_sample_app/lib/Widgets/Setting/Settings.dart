import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late SharedPreferences _prefs;
  late TextEditingController _ipController = TextEditingController();
  TimeOfDay _openingTime = TimeOfDay.now();
  TimeOfDay _closingTime = TimeOfDay.now();
  String _selectedInverter = 'Growatt';
  late TextEditingController number_of_panels = TextEditingController();
  late TextEditingController latitude = TextEditingController();
  late TextEditingController longitude = TextEditingController();
  String generator_type = 'Counter';
  List<String> _inverters = ['Growatt', 'Voltronic', 'Deye', 'Must'];
  List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  List<String> _GeneratorType = ['Counter', 'CutOff'];
  late bool isChecked = false;
  String selectedDay = 'Monday';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TimeOfDay _stringToTimeOfDay(String? timeString) {
    if (timeString != null && timeString.isNotEmpty) {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return TimeOfDay.now();
  }

  String _timeOfDayToString(TimeOfDay time) {
    final formattedHour = time.hour.toString().padLeft(2, '0');
    final formattedMinute = time.minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute';
  }

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _ipController = TextEditingController();
    number_of_panels = TextEditingController();
    latitude = TextEditingController();
    longitude = TextEditingController();
  }

  void _showResponseMessage(String message) {
    if (!mounted) return;
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = _prefs.getString('ipAddress') ?? '';
      _selectedInverter = _prefs.getString('selectedInverter') ?? _inverters[0];
      _openingTime = _stringToTimeOfDay(_prefs.getString('openingTime') ?? '');
      _closingTime = _stringToTimeOfDay(_prefs.getString('closingTime') ?? '');
      number_of_panels.text = _prefs.getString('number_of_panels') ?? '1';
      latitude.text = _prefs.getString('latitude') ?? '0.00';
      longitude.text = _prefs.getString('longitude') ?? '0.00';
      generator_type = _prefs.getString('generator_type') ?? 'Counter';
      isChecked = _prefs.getBool('isChecked') ?? false;
    });
  }

  Future<void> _sendRequestToServer() async {
    var url = Uri.parse('http://192.168.1.16:8000/parameters');

    try {
      var requestBody = {
        "latitude": latitude.text,
        "longitude": longitude.text,
        "panel_number": int.tryParse(number_of_panels.text) ??
            0, // Ensure a default value if parsing fails
        "GeneratorType": generator_type,
        'openingTime': _timeOfDayToString(_openingTime),
        'closingTime': _timeOfDayToString(_closingTime),
        'InverterType': _selectedInverter,
      };

      var response = await http.post(
        url,
        body: json.encode(requestBody),
        headers: {
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var serverMessage = responseData['message'];
        print('Request sent successfully');
        _showResponseMessage(serverMessage);
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        _showResponseMessage(
            'Failed to send request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending request: $e');
      _showResponseMessage('Error sending request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                /*DropdownButtonFormField<String>(
                value: selectedDay,
                onChanged: isChecked
                    ? null
                    : (newValue) {
                        setState(() {
                          selectedDay = newValue!;
                        });
                      },
                items: _days.map((day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Day of the week',
                  // Assuming primaryColor is defined elsewhere
                  fillColor: primaryColor,
                  labelStyle: TextStyle(color: primaryColor),
                  border: OutlineInputBorder(),
                ),
              ),*/
                SizedBox(height: 20.0),
                ListTile(
                  title: Text(
                    'Generator Starting Time',
                    style: TextStyle(color: primaryColor),
                  ),
                  trailing: SizedBox(
                    width: 100.0,
                    child: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _openingTime,
                        );
                        if (pickedTime != null && pickedTime != _openingTime) {
                          setState(() {
                            _openingTime = pickedTime;
                          });
                        }
                      },
                      child: Text(_openingTime.format(context)),
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                ListTile(
                  title: Text('Generator Cutoff Time',
                      style: TextStyle(color: primaryColor)),
                  trailing: SizedBox(
                    width: 100.0,
                    child: ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _closingTime,
                        );
                        if (pickedTime != null && pickedTime != _closingTime) {
                          setState(() {
                            _closingTime = pickedTime;
                          });
                        }
                      },
                      child: Text(_closingTime.format(context)),
                    ),
                  ),
                ),
                /*CheckboxListTile(
                title: Text('Apply to all Days'),
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    isChecked = value!;
                    _prefs.setBool('isChecked', value);
                  });
                },
              ),*/
                SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: generator_type,
                  onChanged: (newValue) {
                    setState(() {
                      generator_type = newValue!;
                    });
                  },
                  items: _GeneratorType.map((inverter) {
                    return DropdownMenuItem<String>(
                      value: inverter,
                      child: Text(inverter),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Generator Type',
                    fillColor: primaryColor,
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: _selectedInverter,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedInverter = newValue!;
                    });
                  },
                  items: _inverters.map((inverter) {
                    return DropdownMenuItem<String>(
                      value: inverter,
                      child: Text(inverter),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Inverter Type',
                    fillColor: primaryColor,
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: number_of_panels,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Number of Panels',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: latitude,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  controller: longitude,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    await _prefs.setString('ipAddress', _ipController.text);
                    await _prefs.setString(
                        'selectedInverter', _selectedInverter);
                    await _prefs.setString(
                        'number_of_panels', number_of_panels.text);
                    await _prefs.setString('latitude', latitude.text);
                    await _prefs.setString('longitude', longitude.text);
                    await _prefs.setString('generator_type', generator_type);
                    await _prefs.setString(
                        'openingTime', _timeOfDayToString(_openingTime));
                    await _prefs.setString(
                        'closingTime', _timeOfDayToString(_closingTime));

                    String ipAddress = _ipController.text;
                    print('Sending request to server with IP: $ipAddress');
                    await _sendRequestToServer();
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
