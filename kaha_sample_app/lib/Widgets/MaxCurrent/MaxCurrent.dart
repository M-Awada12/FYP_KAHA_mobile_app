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

class _MaxCurrentState extends State<MaxCurrent> {
  late SharedPreferences _prefs;
  late TextEditingController _ipController;
  late TextEditingController maxCurrent = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _initSharedPreferences();
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
      maxCurrent.text = _prefs.getString('MaxCurrent') ?? '10';
    });
  }

  Future<void> _sendRequestToServer(String ipAddress) async {
    var url = Uri.parse('http://$ipAddress:8000/MaxCurrent');

    try {
      var requestBody = json.encode(maxCurrent.text);

      var response = await http.post(
        url,
        body: requestBody,
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
              SizedBox(height: 20),
              TextFormField(
                controller: maxCurrent,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Max Charging Current (in A)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  await _prefs.setString('MaxCurrent', maxCurrent.text);
                  String ipAddress = _ipController.text;
                  print('Sending request to server with IP: $ipAddress');
                  await _sendRequestToServer(ipAddress);
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