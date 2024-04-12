// ignore_for_file: file_names, library_private_types_in_public_api
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class CustomBox extends StatefulWidget {
  final String number;
  final String label;

  CustomBox({
    Key? key,
    required this.number,
    required this.label,
  }) : super(key: key);

  @override
  _CustomBoxState createState() => _CustomBoxState();
}

class LineGraph extends StatelessWidget {
  final List<double> data;

  LineGraph({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200.0,
      child: CustomPaint(
        painter: LineGraphPainter(data),
      ),
    );
  }
}

class LineGraphPainter extends CustomPainter {
  final List<double> data;

  LineGraphPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    double width = size.width;
    double height = size.height;

    double maxY = data.reduce((curr, next) => curr > next ? curr : next);
    double minY = data.reduce((curr, next) => curr < next ? curr : next);

    double yScale = height / (maxY - minY);
    double xScale = width / (data.length - 1);

    Path path = Path();
    path.moveTo(0, height - (data[0] - minY) * yScale);

    for (int i = 1; i < data.length; i++) {
      path.lineTo(i * xScale, height - (data[i] - minY) * yScale);
    }

    canvas.drawLine(Offset(0, height), Offset(width, height), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, height), paint);

    final yLabelsCount = 5;
    final yLabelInterval = (maxY - minY) / (yLabelsCount - 1);
    for (int i = 0; i < yLabelsCount; i++) {
      double yLabelValue = minY + (i * yLabelInterval);
      TextSpan span = TextSpan(
        text: yLabelValue.toStringAsFixed(1),
        style: TextStyle(color: Colors.black),
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas,
          Offset(-tp.width - 5,
              height - (yLabelValue - minY) * yScale - tp.height / 2));
    }

    // Drawing labels for x-axis
    for (int i = 0; i < data.length; i++) {
      TextSpan span = TextSpan(
        text: i.toString(),
        style: TextStyle(color: Colors.black),
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(i * xScale - tp.width / 2, height + 5));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _CustomBoxState extends State<CustomBox> {
  late String currentNumber;

  @override
  void initState() {
    super.initState();
    currentNumber = widget.number;
  }

  void showGraph() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.symmetric(horizontal: 45, vertical: 40),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Graph'),
              LineGraph(data: [20, 40, 30, 50, 70, 45, 60]),
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 1.0),
                    child: TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //onTap: showGraph,
      child: Container(
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: Colors.blue,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$currentNumber',
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5.0, width: 90),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Status extends StatefulWidget {
  @override
  _StatusState createState() => _StatusState();
}

class _StatusState extends State<Status> {
  late SharedPreferences _prefs;
  late TextEditingController _ipController;
  String current1 = '';
  String current2 = '';
  String current3 = '';
  bool gotData = false;

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
    _sendRequestToServer();
  }

  void _showResponseMessage(String message) {
    if (!mounted) return; // Check if the state is still active

    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _sendRequestToServer() async {
    var url = Uri.parse('http://192.168.1.16:8000/data');
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        //var serverMessage = Map<String, dynamic>.from(responseData);
        setState(() {
          current1 = responseData['Solar Panel Current'];
          current2 = responseData['Load Current'];
          current3 = responseData['Grid Current'];
          gotData = true;
        });
      } else {
        print('Failed to send request. Status code: ${response.statusCode}');
        current1 = '';
        current2 = '';
        current3 = '';
        _showResponseMessage(
            'Failed to send request. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending request: $e');
      _showResponseMessage('Error sending request: $e');
      current1 = '';
      current2 = '';
      current3 = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: gotData
            ? [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomBox(number: current1, label: ' Solar Current '),
                    CustomBox(number: current2, label: ' Solar Voltage '),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomBox(number: current3, label: ' Grid Current '),
                    CustomBox(number: '220 V', label: ' Grid Voltage '),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomBox(number: '5.7 W', label: ' Batt. Power '),
                    CustomBox(number: '6.1 A', label: ' Batt. Current '),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomBox(number: '7.6 W', label: ' Solar Power '),
                    CustomBox(number: '5.2 W', label: ' Grid Power '),
                  ],
                ),
              ]
            : [
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
        /*Text(
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
          ),*/
      ),
    );
  }
}
