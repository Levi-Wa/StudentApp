import 'package:studentApp/features/repository/schedule_repository.dart';
import 'package:studentApp/features/Widgets/widgents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studentApp/features/StartView/StartScreenApp.dart';

void main() => runApp(const Startscreenapp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Root widget
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My Home Page'),
        ),
        body: Center(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  const Text('Hello, World!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      print('Click!');
                    },
                    child: const Text('A button'),
                  ),
                ],
              );

            },
            
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.download) ,
          onPressed: () {
            ScheduleRepository();
          },
        )
      )
    );
  }
}

