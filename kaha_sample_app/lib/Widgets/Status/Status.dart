// ignore_for_file: file_names, library_private_types_in_public_api
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class Status extends StatefulWidget {
  @override
  _StatusState createState() => _StatusState();
}

class _StatusState extends State<Status> {
  late SharedPreferences _prefs;
  late TextEditingController _ipController;
  String current = '';

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = _prefs.getString('ipAddress') ?? '';
    });
    _sendRequestToServer(_ipController.text);
  }

  void _showResponseMessage(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _sendRequestToServer(String ipAddress) async {
    var url = Uri.parse('http://$ipAddress:8000/getCurrent');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var serverMessage = responseData['message'];
        setState(() {
          current = serverMessage;
        });
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        _showResponseMessage('Failed to send request. Status code: ${response.statusCode}');
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Charging Current',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              current,
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}