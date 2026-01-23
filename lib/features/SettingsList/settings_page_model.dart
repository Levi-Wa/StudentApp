import 'package:flutter/material.dart';

class SettingsPageModel extends ChangeNotifier {
  bool? switchValue1;
  bool? switchValue2;
  bool? switchValue3;

  String? dropDownValue1;
  String? dropDownValue2;
  String? dropDownValue3;
  String? dropDownValue4;

  void dispose() {
    // Cleanup if needed
  }
}
