// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:uvc/uvc.dart';

class CheckboxControl extends StatefulWidget {
  const CheckboxControl(
      {super.key, required this.title, required this.controller});

  final String title;
  final UvcController controller;

  @override
  State<CheckboxControl> createState() => _CheckboxControlState();
}

class _CheckboxControlState extends State<CheckboxControl> {
  int _value = 0;
  int _minValue = 0;
  int _maxValue = 0;
  int _defaultVal = 0;
  bool _controlSupported = false;

  @override
  void initState() {
    _updateValues();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CheckboxControl oldWidget) {
    _updateValues();
    super.didUpdateWidget(oldWidget);
  }

  void _updateValues() {
    try {
      _minValue = widget.controller.min ?? 0;
      _maxValue = widget.controller.max ?? 0;
      _value = widget.controller.current ?? 0;
      _defaultVal = widget.controller.defaultValue ?? 0;
      _controlSupported = (_minValue + _maxValue + _value + _defaultVal) != 0;
    } catch (e) {
      _minValue = _maxValue = _value = _defaultVal = 0;

      _controlSupported = false;
      // ignore: avoid_print
      print('dive_av: exception: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title),
          Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: _value == 1,
            visualDensity: VisualDensity.compact,
            onChanged: (bool? value) {
              if (_controlSupported) {
                setState(() {
                  _value = value == true ? 1 : 0;
                  try {
                    widget.controller.current = _value;
                  } catch (e) {
                    _controlSupported = false;
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
