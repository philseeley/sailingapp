import 'dart:math';

import 'package:flutter/material.dart';
import 'package:boatinstrument/boatinstrument_controller.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wind_rose_box.g.dart';

// enum WindRoseType {
//   normal('Normal'),
//   closeHaul('Close Haul'),
//   auto('Auto');
//
//   final String displayName;
//
//   const WindRoseType(this.displayName);
// }

@JsonSerializable()
class _Settings {
  // WindRoseType type;
  bool showLabels;
  // bool showButton;

  _Settings({
    // this.type = WindRoseType.normal,
    this.showLabels = true,
    // this.showButton = false
  });
}

class _RosePainter extends CustomPainter {
  final BuildContext _context;
  final _Settings _settings;

  _RosePainter(this._context, this._settings);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Color fg = Theme.of(_context).colorScheme.onSurface;
    double size = min(canvasSize.width, canvasSize.height);

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = fg
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(size/2, size/2), size/2, paint);
    paint..strokeWidth = 20.0..color = Colors.green;
    canvas.drawArc(const Offset(10.0, 10.0) & Size(size-20.0, size-20.0), deg2Rad((20).toInt())-(pi/2), deg2Rad((40).toInt()), false, paint);
    paint.color = Colors.red;
    canvas.drawArc(const Offset(10.0, 10.0) & Size(size-20.0, size-20.0), deg2Rad((-20).toInt())-(pi/2), deg2Rad((-40).toInt()), false, paint);
    paint.color = fg;

    for(int a = 0; a < 360; a += 10) {
      paint.strokeWidth = 10.0;
      double width = 0.01;
      if (a % 30 == 0) {
        paint.strokeWidth = 20.0;
        width = 0.02;
      }

      canvas.drawArc(const Offset(10.0, 10.0) & Size(size-20.0, size-20.0), deg2Rad(a)-(pi/2)-(width/2), width, false, paint);
    }

    if(_settings.showLabels) {
      TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
      canvas.translate(size / 2, size / 2);
      for (int a = 0; a <= 180; a += 30) {
        tp.text = TextSpan(text: a.toString(), style: Theme
            .of(_context)
            .textTheme
            .bodyMedium);
        tp.layout();
        double x = cos(deg2Rad(a) - (pi / 2)) * (size / 2 - 40.0);
        double y = sin(deg2Rad(a) - (pi / 2)) * (size / 2 - 40.0);
        tp.paint(canvas, Offset(x - tp.size.width / 2, y - tp.size.height / 2));
        tp.paint(canvas, Offset(-x - tp.size.width / 2, y - tp.size.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeedlePainter extends CustomPainter {

  final Color _color;
  final double _angle;

  _NeedlePainter(this._color, this._angle);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    double size = min(canvasSize.width, canvasSize.height);
    Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _color;

    Path needle = Path()
      ..moveTo(-10.0, 0.0)
      ..lineTo(0.0, -size/2)
      ..lineTo(10.0, 0.0)
      ..moveTo(0.0, 0.0)
      ..addArc(const Offset(-10, -10.0) & const Size(20.0, 20.0), 0.0, pi)
      ..close();
    canvas.translate(size/2, size/2);
    canvas.rotate(_angle);
    canvas.drawPath(needle, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WindRoseBox extends BoxWidget {
  late _Settings _settings;

   WindRoseBox(super.config, {super.key}) {
    _settings = _$SettingsFromJson(config.settings);
  }

  @override
  State<WindRoseBox> createState() => _WindRoseBoxState();

  static String sid = 'wind-rose';
  @override
  String get id => sid;

  @override
  bool get hasPerBoxSettings => true;

  @override
  Widget getPerBoxSettingsWidget() {
    return _SettingsWidget(_settings);
  }

  @override
  Map<String, dynamic> getPerBoxSettingsJson() {
    return _$SettingsToJson(_settings);
  }

  // @override
  // Widget? getPerBoxSettingsHelp() {
  //   return const Text('''The Switch Button allow you to cycle through the Wind Rose types from the display.''');
  // }
}

class _WindRoseBoxState extends State<WindRoseBox> {
  double? _windAngleApparent;
  double? _windAngleTrue;
  late _RosePainter _rosePainter;

  @override
  void initState() {
    super.initState();
    widget.config.controller.configure(widget, onUpdate: _processData, paths: {
      'environment.wind.angleApparent',
      'environment.wind.angleTrueWater'
    });

    _rosePainter = _RosePainter(context, widget._settings);
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> stack = [
      CustomPaint(size: Size.infinite, painter: _rosePainter)// _RosePainter(context, widget._type))
    ];

    if(_windAngleTrue != null) {
      double angleTrue = _windAngleTrue!;
      stack.add(CustomPaint(size: Size.infinite, painter: _NeedlePainter(Colors.yellow, angleTrue)));
    }

    if(_windAngleApparent != null) {
      double angleApparent = _windAngleApparent!;
      stack.add(CustomPaint(size: Size.infinite, painter: _NeedlePainter(Colors.blue, angleApparent)));
    }

    // if(widget._settings.showButton) {
    //   stack.add(Positioned(right: 0, bottom: 0, child:
    //   IconButton(icon: Icon((widget._settings.type == WindRoseType.auto) ? Icons.lock_open : Icons.lock),
    //       onPressed: _cycleType))
    //   );
    // }

    return Container(padding: const EdgeInsets.all(5.0), child: Stack(children: stack));
  }

  // void _cycleType () {
  //   setState(() {
  //     switch (widget._settings.type) {
  //       case WindRoseType.normal:
  //         widget._settings.type = WindRoseType.closeHaul;
  //         break;
  //       case WindRoseType.closeHaul:
  //         widget._settings.type = WindRoseType.auto;
  //         break;
  //       case WindRoseType.auto:
  //         widget._settings.type = WindRoseType.normal;
  //         break;
  //     }
  //   });
  // }

  _processData(List<Update> updates) {
    for (Update u in updates) {
      try {
        switch (u.path) {
          case 'environment.wind.angleApparent':
            double latest = (u.value as num).toDouble();
            _windAngleApparent = averageAngle(
                _windAngleApparent ?? latest, latest,
                smooth: widget.config.controller.valueSmoothing);
            break;
          case 'environment.wind.angleTrueWater':
            double latest = (u.value as num).toDouble();
            _windAngleTrue = averageAngle(
                _windAngleTrue ?? latest, latest,
                smooth: widget.config.controller.valueSmoothing);
            break;
        }
      } catch (e) {
        widget.config.controller.l.e("Error converting $u", error: e);
      }

      if (mounted) {
        setState(() {});
      }
    }
  }
}

class _SettingsWidget extends StatefulWidget {
  final _Settings _settings;

  const _SettingsWidget(this._settings);

  @override
  createState() => _SettingsState();
}

class _SettingsState extends State<_SettingsWidget> {

  @override
  Widget build(BuildContext context) {
    _Settings s = widget._settings;

    return ListView(children: [
      // ListTile(
      //     leading: const Text("Type:"),
      //     title: _roseTypeMenu()
      // ),
      SwitchListTile(title: const Text("Show Labels:"),
          value: s.showLabels,
          onChanged: (bool value) {
            setState(() {
              s.showLabels = value;
            });
          }),
      // SwitchListTile(title: const Text("Show Switch Button:"),
      //     value: s.showButton,
      //     onChanged: (bool value) {
      //       setState(() {
      //         s.showButton = value;
      //       });
      //     }),
    ]);
  }

  // DropdownMenu _roseTypeMenu() {
  //   List<DropdownMenuEntry<WindRoseType>> l = [];
  //   for(var v in WindRoseType.values) {
  //     l.add(DropdownMenuEntry<WindRoseType>(
  //         value: v,
  //         label: v.displayName));
  //   }
  //
  //   DropdownMenu menu = DropdownMenu<WindRoseType>(
  //     initialSelection: widget._settings.type,
  //     dropdownMenuEntries: l,
  //     onSelected: (value) {
  //       widget._settings.type = value!;
  //     },
  //   );
  //
  //   return menu;
  // }
}
