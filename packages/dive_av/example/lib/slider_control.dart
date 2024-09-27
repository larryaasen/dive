// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:uvc/uvc.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class SliderControl extends StatefulWidget {
  const SliderControl({super.key, this.title = '', this.titleWidget, required this.controller});

  final String title;
  final Widget? titleWidget;
  final UvcController controller;

  @override
  State<SliderControl> createState() => _SliderControlState();
}

class _SliderControlState extends State<SliderControl> {
  int _resolution = 0;
  int _sliderValue = 0;
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
  void didUpdateWidget(covariant SliderControl oldWidget) {
    _updateValues();
    super.didUpdateWidget(oldWidget);
  }

  void _updateValues() {
    try {
      _resolution = widget.controller.resolution ?? 0;
      _minValue = widget.controller.min ?? 0;
      _maxValue = widget.controller.max ?? 0;
      _sliderValue = widget.controller.current ?? 0;
      _defaultVal = widget.controller.defaultValue ?? 0;
      _controlSupported = (_minValue + _maxValue + _sliderValue + _defaultVal) != 0;
    } catch (e) {
      _minValue = _maxValue = _sliderValue = _defaultVal = 0;

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
    return Row(
      children: [
        if (widget.titleWidget != null) widget.titleWidget!,
        if (widget.titleWidget == null)
          SizedBox(
              width: 80,
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 12.0),
              )),
        Expanded(
          child: SfSliderTheme(
            data: const SfSliderThemeData(
              activeTrackHeight: 1,
              inactiveTrackHeight: 1,
              thumbRadius: 8,
            ),
            child: SizedBox(
              height: 1.0,
              child: _controlSupported
                  ? SfSlider(
                      activeColor: Colors.blue,
                      min: _minValue.toDouble(),
                      max: _maxValue.toDouble(),
                      value: _sliderValue.toDouble(),
                      interval:
                          _resolution > 0 ? ((_maxValue - _minValue) / _resolution).round().toDouble() : null,
                      showTicks: true,
                      showLabels: false,
                      enableTooltip: true,
                      minorTicksPerInterval: 1,
                      onChanged: (dynamic value) {
                        setState(() {
                          if (_controlSupported) {
                            setState(() {
                              _sliderValue = value.round();
                              try {
                                widget.controller.current = _sliderValue;
                              } catch (e) {
                                _controlSupported = false;
                              }
                            });
                          }
                        });
                      },
                    )
                  : SfSlider(
                      activeColor: Colors.blue,
                      value: 0,
                      onChanged: (value) {},
                    ),
            ),
          ),
          // child: Slider(
          //   value: _sliderValue.toDouble(),
          //   min: _minValue.toDouble(),
          //   max: _maxValue.toDouble(),
          //   divisions: _resolution > 0 ? ((_maxValue - _minValue) / _resolution).round() : null,
          //   activeColor: Colors.blue,
          //   inactiveColor: Colors.black26,
          //   thumbColor: Colors.white,
          //   label: _sliderValue.round().toString(),
          //   onChanged: (double value) {
          //     if (_controlSupported) {
          //       setState(() {
          //         _sliderValue = value.round();
          //         try {
          //           widget.controller.current = _sliderValue;
          //         } catch (e) {
          //           _controlSupported = false;
          //         }
          //       });
          //     }
          //   },
          // ),
        ),
        IconButton(
          iconSize: 20.0,
          padding: EdgeInsets.zero,
          tooltip: 'Reset',
          onPressed: _controlSupported
              ? () {
                  setState(() {
                    _sliderValue = _defaultVal;
                    try {
                      widget.controller.current = _defaultVal;
                    } catch (e) {
                      _controlSupported = false;
                    }
                  });
                }
              : null,
          icon: const Icon(Icons.restore),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
