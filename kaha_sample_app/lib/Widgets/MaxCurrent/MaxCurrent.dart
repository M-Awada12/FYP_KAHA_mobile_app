// ignore_for_file: file_names, library_private_types_in_public_api
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class MaxCurrent extends StatefulWidget {
  @override
  _MaxCurrentState createState() => _MaxCurrentState();
}

class Activity {
  final String name;
  final String startTime;
  final String endTime;

  Activity(this.name, this.startTime, this.endTime);
}

class MyTable extends StatelessWidget {
  final List<Activity> activities;

  MyTable({required this.activities});

  @override
  Widget build(BuildContext context) {
    List<String> hours =
        List.generate(24, (index) => '${index.toString().padLeft(2, '0')}:00');

    return Table(
      columnWidths: {
        0: FlexColumnWidth(0.5),
      },
      border: TableBorder.all(),
      children: List.generate(
        hours.length,
        (index) => TableRow(
          children: [
            TableCell(
              child: Container(
                height: 23.4,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                ),
                alignment: Alignment.center,
                child: buildActivitiesForHour(hours[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActivitiesForHour(String hour) {
    List<Widget> hourActivities = [];
    bool foundActivity = false;

    for (var activity in activities) {
      if (activity.startTime == hour) {
        hourActivities.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Container(
              height: 17.4,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${activity.name} (${activity.startTime} - ${activity.endTime})',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
        foundActivity = true;
      }
    }

    if (!foundActivity) {
      hourActivities.add(
        Text(
          hour,
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return Column(
      children: hourActivities,
    );
  }
}

class _MaxCurrentState extends State<MaxCurrent> {
  late SharedPreferences _prefs;
  late TextEditingController _ipController;
  late TextEditingController maxCurrent = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<String> _status = ['Never', 'Sometimes', 'always'];
  late bool isYesSelected = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _initSharedPreferences();
  }

  void _showResponseMessage(String message) {
    if (!mounted) return; // Check if the state is still active

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
      maxCurrent.text = _prefs.getString('MaxCurrent') ?? '10';
      isYesSelected = _prefs.getBool('isYesSelected') ?? false;
    });
  }

  Future<void> _sendRequestToServer() async {
    var url = Uri.parse('https://kaha-cloud-server.onrender.com/MaxCurrent');

    try {
      // Parse maxCurrent.text to ensure it's a valid float
      double? maxCurrentValue = double.tryParse(maxCurrent.text);
      if (maxCurrentValue == null) {
        // Handle invalid input
        print('Invalid max current value: ${maxCurrent.text}');
        return;
      }

      // Prepare the data to be sent in the request
      Map<String, dynamic> data = {
        'value': maxCurrentValue,
        'automatic': isYesSelected,
      };

      // Send the POST request
      var response = await http.post(
        url,
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json', // Specify JSON content type
        },
      );

      // Check the response status code
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var serverMessage = responseData['message'];
        print('Request sent successfully');
        _showResponseMessage(serverMessage);
      } else {
        // Handle unsuccessful request
        print('Failed to send request. Status code: ${response.statusCode}');
        _showResponseMessage(
            'Failed to send request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
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
                'Max Charging Current',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              Row(
                children: [
                  Radio(
                    value: true,
                    groupValue: isYesSelected,
                    onChanged: (newValue) {
                      setState(() {
                        isYesSelected = true;
                        _prefs.setBool('isYesSelected', true);
                      });
                    },
                  ),
                  Text(
                    'Automatically',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  SizedBox(width: 20),
                  Radio(
                    value: false,
                    groupValue: isYesSelected,
                    onChanged: (newValue) {
                      setState(() {
                        isYesSelected = false;
                        _prefs.setBool('isYesSelected', false);
                      });
                    },
                  ),
                  Text(
                    'Manually',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              TextFormField(
                controller: maxCurrent,
                enabled: !isYesSelected,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Charging Current (in A)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              /*ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Appliances'),
                        content: Column(
                          children: <Widget>[
                            DropdownButtonFormField<String>(
                              /*value: _selectedInverter,*/
                              onChanged: (newValue) {
                                /*setState(() {
                                  _selectedInverter = newValue!;
                                });*/
                              },
                              items: _status.map((inverter) {
                                return DropdownMenuItem<String>(
                                  value: inverter,
                                  child: Text(inverter),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                labelText: 'Washing Machine',
                                fillColor: primaryColor,
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Appliances'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Appliances Schedule'),
                        content: Column(
                          children: <Widget>[
                            MyTable(activities: [
                              Activity('Washing Machine', '09:00', '10:00'),
                              Activity('Heater', '12:00', '13:00'),
                              Activity('TV', '17:00', '18:00'),
                            ]),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Schedule'),
              ),*/
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  await _prefs.setString('MaxCurrent', maxCurrent.text);
                  String ipAddress = _ipController.text;
                  print('Sending request to server with IP: $ipAddress');
                  await _sendRequestToServer();
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
