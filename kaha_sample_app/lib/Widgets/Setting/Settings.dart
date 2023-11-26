// ignore_for_file: library_private_types_in_public_api, file_names
import 'dart:convert';
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
  List<String> _inverters = ['Growatt', 'Voltronic', 'Deye'];
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
  }

  void _showResponseMessage(String message) {
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
    });
  }

  Future<void> _sendRequestToServer(String ipAddress) async {
    var url = Uri.parse('http://$ipAddress:8000/data');

    try {
      var requestBody = json.encode({
        'openingTime': _timeOfDayToString(_openingTime),
        'closingTime': _timeOfDayToString(_closingTime),
        'selectedInverter': _selectedInverter,
      });

      var response = await http.post(
        url,
        body: requestBody,
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var serverMessage = responseData[
            'message'];
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
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: 'Enter IP Address',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  await _prefs.setString('ipAddress', _ipController.text);
                  await _prefs.setString('selectedInverter', _selectedInverter);
                  await _prefs.setString(
                      'openingTime', _timeOfDayToString(_openingTime));
                  await _prefs.setString(
                      'closingTime', _timeOfDayToString(_closingTime));

                  String ipAddress = _ipController.text;
                  print('Sending request to server with IP: $ipAddress');
                  await _sendRequestToServer(ipAddress);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}