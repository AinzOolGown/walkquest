import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _steps = 0;
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    initStepCounter();
  }

  Future<void> initStepCounter() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream;

      _stepCountStream.listen(
        onStepCount,
        onError: onStepError,
        cancelOnError: true,
      );
    } else {
      print("Permission denied");
    }
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
    });
  }

  void onStepError(error) {
    print("Step Count Error: $error");
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:  
          Text(
            'Total Steps: $_steps',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
      ),
    );
  }
}