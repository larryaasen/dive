import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
            SourceMenu(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class SourceMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<int>(
          child: Icon(Icons.settings_outlined, color: Colors.grey),
          tooltip: 'Source menu',
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<int>(
                key: Key('SourceMenu_1'),
                value: 1,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.clear, color: Colors.grey),
                    Padding(padding: EdgeInsets.only(left: 6.0), child: Text('Clear')),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                key: Key('SourceMenu_2'),
                value: 2,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.clear, color: Colors.grey),
                    Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: DiveSubMenu(
                        'Select source',
                        [
                          {
                            'id': '111',
                            'title': 'Camera 1',
                            'icon': Icons.clear,
                            'subMenu': Null,
                          }
                        ],
                        onCanceled: () {},
                        onSelected: (item) {},
                      ),
                    ),
                  ],
                ),
              ),
            ].toList();
          },
          onSelected: (int item) {
            // TODO: this is not being called
            print("onSelected: $item");
          },
          onCanceled: () {
            // TODO: this is not being called
            print("onCanceled");
          },
        ));
  }
}

class DiveSubMenu extends StatelessWidget {
  DiveSubMenu(this.title, this.popupItems, {required this.onSelected, required this.onCanceled});

  final String title;
  final List<Map<String, Object>> popupItems;

  /// Called when the user selects a value from the popup menu created by this
  /// menu.
  /// If the popup menu is dismissed without selecting a value, [onCanceled] is
  /// called instead.
  final void Function(Map<String, Object> item) onSelected;

  /// Called when the user dismisses the popup menu without selecting an item.
  ///
  /// If the user selects a value, [onSelected] is called instead.
  final void Function() onCanceled;

  @override
  Widget build(BuildContext context) {
    final mainChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title),
        // Spacer(),
        Icon(Icons.arrow_right, size: 30.0),
      ],
    );
    return Padding(
        padding: EdgeInsets.only(left: 0.0, right: 0.0),
        child: PopupMenuButton<Map<String, Object>>(
          child: mainChild,
          tooltip: title,
          padding: EdgeInsets.only(right: 0.0),
          offset: Offset(0.0, 0.0),
          itemBuilder: (BuildContext context) {
            return popupItems.map((Map<String, dynamic> item) {
              return PopupMenuItem<Map<String, Object>>(
                  key: Key('diveSubMenu_${item['id']}'),
                  value: item as Map<String, Object>?,
                  child: Flexible(
                      child: Row(children: <Widget>[
                    Icon(item['icon'], color: Colors.grey),
                    Padding(
                        padding: EdgeInsets.only(left: 6.0),
                        child: Text(
                          item['title'].toString().substring(0, min(14, item['title'].toString().length)),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ])));
            }).toList();
          },
          onSelected: (item) {
            this.onSelected(item);

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          onCanceled: () {
            this.onCanceled();

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ));
  }
}
