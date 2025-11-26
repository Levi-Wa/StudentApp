import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Schedulelist extends StatefulWidget {
  const Schedulelist({super.key});

  @override
  State<Schedulelist> createState() => _SchedulelistState();
}

class _SchedulelistState extends State<Schedulelist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListTile(

        )
      ),
      drawer: Drawer( 

      ),
    ) ;
  }
}
