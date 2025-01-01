// Copyright (c) 2025 Larry Aasen. All rights reserved.

import 'package:dive_av/dive_av.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tide/tide.dart';

class AudioDevice extends Equatable {
  const AudioDevice({
    required this.name,
    required this.id,
    required this.input,
  });

  final String name;
  final String id;
  final DiveAVInput input;

  AudioDevice copyWith({String? name, String? id, DiveAVInput? input}) {
    return AudioDevice(
      name: name ?? this.name,
      id: id ?? this.id,
      input: input ?? this.input,
    );
  }

  @override
  List<Object> get props => [name, id, input];
}

class AudioDevicesState extends Equatable {
  final List<AudioDevice> devices;

  const AudioDevicesState({this.devices = const []});

  AudioDevicesState copyWith({List<AudioDevice>? devices}) {
    return AudioDevicesState(
      devices: devices ?? this.devices,
    );
  }

  @override
  List<Object> get props => [devices];
}

/// Dive Caster Multi Camera Streaming and Recording
class DiveAudioDevicesApp extends StatelessWidget {
  final tide = Tide();
  final tideOS = TideOS();
  final statusBarColor = ValueNotifier<Color?>(null);
  final timeNotification = ValueNotifier<TideNotification?>(null);
  final audioDevicesState =
      ValueNotifier<AudioDevicesState>(const AudioDevicesState());
  final selectedAudioDevice = ValueNotifier<AudioDevice?>(null);
  final leftPanelId = TideId.uniqueId();
  final mainPanelId = TideId.uniqueId();

  final _diveAvPlugin = DiveAv();

  DiveAudioDevicesApp({super.key}) {
    tide.useServices(services: [Tide.ids.service.time]);

    final workbenchService = Tide.get<TideWorkbenchService>();
    workbenchService.layoutService.addPanels([
      TidePanel(panelId: leftPanelId),
      TidePanel(panelId: mainPanelId),
    ]);

    // An example of using a child status bar item that is clickable and changes the status bar color.
    tide.workbenchService.layoutService.addStatusBarItem(TideStatusBarItem(
      position: TideStatusBarItemPosition.left,
      builder: (context, item) {
        return TideStatusBarItemContainer(
          item: item,
          onPressed: (TideStatusBarItem item) {
            statusBarColor.value =
                statusBarColor.value == null ? Colors.red : null;
          },
          tooltip: 'The selected audio device',
          child: ValueListenableBuilder<AudioDevice?>(
              valueListenable: selectedAudioDevice,
              builder: (context, device, child) {
                return Row(
                  children: [
                    const Icon(Icons.mic_none_outlined,
                        size: 16.0, color: Colors.white),
                    const SizedBox(width: 4.0),
                    Text(device?.name ?? '',
                        style: TideStatusBarItemTextWidget.style),
                  ],
                );
              }),
        );
      },
    ));

    // An example of using a time status bar item.
    tide.workbenchService.layoutService.addStatusBarItem(TideStatusBarItemTime(
      position: TideStatusBarItemPosition.right,
      tooltip: 'The current time',
      onPressed: (TideStatusBarItem item) {
        final notificationService = Tide.get<TideNotificationService>();
        if (timeNotification.value == null ||
            !notificationService
                .notificationExists(timeNotification.value!.id)) {
          final timeService = Tide.get<TideTimeService>();
          final msg =
              'The time is: ${timeService.currentTimeState.timeFormatted()}';
          timeNotification.value = notificationService.info(msg,
              autoTimeout: true, allowClose: false);
        }
      },
    ));

    // Get the input devices.
    Future.delayed(Duration.zero, () async {
      // Platform messages may fail, so we use a try/catch PlatformException.
      // We also handle the message potentially returning null.
      try {
        final inputs = await _diveAvPlugin.inputsFromType('audio');

        audioDevicesState.value = AudioDevicesState(
          devices: inputs
              .map((input) => AudioDevice(
                    name: input.localizedName ?? '',
                    id: input.uniqueID,
                    input: input,
                  ))
              .toList(),
        );
      } catch (e) {
        print('error $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color?>(
      valueListenable: statusBarColor,
      builder: (context, colorValue, child) {
        return TideApp(
          home: TideWindow(
            workbench: TideWorkbench(
                panelBuilder: (context, panel) {
                  if (panel.panelId.id == leftPanelId.id) {
                    return TidePanelWidget(
                      panelId: panel.panelId,
                      backgroundColor: const Color(0xFFE0E0DF),
                      position: TidePosition.left,
                      resizeSide: TidePosition.right,
                      minWidth: 100,
                      maxWidth: 450,
                      initialWidth: 220,
                      child: AudioList(
                          audioDevicesState: audioDevicesState,
                          onChanged: (device) {
                            print('Selected device: ${device?.name ?? ''}');
                            selectedAudioDevice.value = device;
                          }),
                    );
                  } else if (panel.panelId.id == mainPanelId.id) {
                    return TidePanelWidget(
                      backgroundColor: Colors.white,
                      expanded: true,
                      position: TidePosition.center,
                      child: ValueListenableBuilder<AudioDevice?>(
                          valueListenable: selectedAudioDevice,
                          builder: (context, device, child) {
                            return DevicePanel(device: device);
                          }),
                    );
                  }
                  return null;
                },
                statusBar: TideStatusBar(backgroundColor: colorValue)),
          ),
        );
      },
    );
  }
}

class DevicePanel extends StatelessWidget {
  const DevicePanel({
    super.key,
    this.device,
  });

  final AudioDevice? device;

  @override
  Widget build(BuildContext context) {
    final ddd =
        '${device?.input.uniqueID}, ${device?.input.locationID}, ${device?.input.vendorID}, ${device?.input.productID}, ${device?.input.typeId}';
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDADAD9))),
            color: Color(0xFFECECEB),
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device?.name ?? '',
                  style: const TextStyle(
                      fontSize: 13.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFE5E5E4),
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ddd,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Colors.black,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

typedef AudioListItemChanged<T> = void Function(T? item);

class AudioList extends StatefulWidget {
  const AudioList({
    super.key,
    required this.audioDevicesState,
    this.onChanged,
  });

  final ValueNotifier<AudioDevicesState> audioDevicesState;
  final AudioListItemChanged<AudioDevice>? onChanged;

  @override
  State<AudioList> createState() => _AudioListState();
}

class _AudioListState extends State<AudioList> {
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();

    final state = widget.audioDevicesState.value;
    if (state.devices.isNotEmpty) {
      _selectedIndex = 0;
      Future.delayed(Duration.zero, () {
        widget.onChanged?.call(state.devices[_selectedIndex]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioDevicesState>(
        valueListenable: widget.audioDevicesState,
        builder: (context, state, child) {
          if (_selectedIndex == -1 && state.devices.isNotEmpty) {
            _selectedIndex = 0;
            Future.delayed(Duration.zero, () {
              widget.onChanged?.call(state.devices[_selectedIndex]);
            });
          } else if (state.devices.length <= _selectedIndex) {
            _selectedIndex = state.devices.length - 1;
            Future.delayed(Duration.zero, () {
              widget.onChanged?.call(state.devices[_selectedIndex]);
            });
          }
          return Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: ListView.builder(
                itemBuilder: (context, index) {
                  final device = state.devices[index];
                  return AudioListItem(
                    device: device,
                    selected: index == _selectedIndex,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      widget.onChanged?.call(device);
                    },
                  );
                },
                itemCount: state.devices.length),
          );
        });
  }
}

class AudioListItem extends StatelessWidget {
  const AudioListItem({
    super.key,
    required this.device,
    this.selected = false,
    this.onTap,
  });

  final AudioDevice device;
  final bool selected;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? const Color(0xFF57A1FF) : null,
        ),
        padding: const EdgeInsets.all(0.0),
        child: Row(
          children: [
            Icon(
              Icons.mic_none_outlined,
              size: 40.0,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name,
                      style: TextStyle(
                          fontSize: 13.0,
                          color: selected ? Colors.white : Colors.black)),
                  Text('1 in / 0 outs',
                      style: TextStyle(
                          fontSize: 11.0,
                          color:
                              selected ? Colors.grey.shade300 : Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
