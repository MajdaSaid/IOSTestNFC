import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin{
  String _platformVersion =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String _result = '';
  late TabController _tabController;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _tabController = new TabController(length: 2, vsync: this);
  }

  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
      print('NFC not available');
    }

    if (!mounted) return;


    setState(() {
      _availability = availability;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFC test'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Running on: $_platformVersion\nNFC: $_availability'),
            ElevatedButton(
              onPressed: () async {
                try {
                  NFCTag tag = await FlutterNfcKit.poll();
                  setState(() {
                    _tag = tag;
                  });
                  await FlutterNfcKit.setIosAlertMessage(
                      "working on it...");
                  if (tag.standard == "ISO 14443-4 (Type A)") {
                    String result1 =
                    await FlutterNfcKit.transceive("00A404000A");
                    String result2 = await FlutterNfcKit.transceive(
                        "00CA010108");
                    setState(() {
                      _result = '$result2\n';
                    });
                  }
                  else if (tag.standard == "ISO 14443-4 (Type B)") {
                    String result1 =
                    await FlutterNfcKit.transceive("00B0950000");
                    String result2 = await FlutterNfcKit.transceive(
                        "00A4040009A00000000386980701");
                    setState(() {
                      _result = '1: $result1\n2: $result2\n';
                    });
                  } else if (tag.type == NFCTagType.iso18092) {
                    String result1 =
                    await FlutterNfcKit.transceive("060080080100");
                    setState(() {
                      _result = '1: $result1\n';
                    });
                  } else if (tag.type == NFCTagType.mifare_ultralight ||
                      tag.type == NFCTagType.mifare_classic) {
                    var ndefRecords = await FlutterNfcKit.readNDEFRecords();
                    var ndefString = ndefRecords
                        .map((r) => r.toString())
                        .reduce((value, element) => value + "\n" + element);
                    setState(() {
                      _result = '1: $ndefString\n';
                    });
                  }
                } catch (e) {
                  setState(() {
                    _result = 'error: $e';
                  });
                }

                // Pretend that we are working
                sleep(new Duration(seconds: 1));
                await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
              },
              child: Text('Start polling'),
            ),
            Text(
                'ID: ${_tag?.id}\nStandard: ${_tag?.standard}\nType: ${_tag?.type}\nATQA: ${_tag?.atqa}\nSAK: ${_tag?.sak}\nHistorical Bytes: ${_tag?.historicalBytes}\nProtocol Info: ${_tag?.protocolInfo}\nApplication Data: ${_tag?.applicationData}\nHigher Layer Response: ${_tag?.hiLayerResponse}\nManufacturer: ${_tag?.manufacturer}\nSystem Code: ${_tag?.systemCode}\nDSF ID: ${_tag?.dsfId}\nNDEF Available: ${_tag?.ndefAvailable}\nNDEF Type: ${_tag?.ndefType}\nNDEF Writable: ${_tag?.ndefWritable}\nNDEF Can Make Read Only: ${_tag?.ndefCanMakeReadOnly}\nNDEF Capacity: ${_tag?.ndefCapacity}\n\n Transceive Result:\n$_result'),
          ],

        ),
      ),

    );
  }
}
