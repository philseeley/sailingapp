import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:format/format.dart' as fmt;
import 'package:boatinstrument/boatinstrument_controller.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'double_value_box.g.dart';

class WaterTemperatureBox extends _DoubleValueBox {
  static const String sid = 'sea-temperature';
  @override
  String get id => sid;

  WaterTemperatureBox(config, {super.key}) : super(config, 'Water Temp', 'environment.water.temperature') {
    _setup(_convertTemp, _tempUnits);
  }

  double _convertTemp(double temp) {
    switch (config.controller.temperatureUnits) {
      case TemperatureUnits.c:
        return temp - 273.15;
      case TemperatureUnits.f:
        return (temp - 273.15) * 9/5 + 32;
    }
  }

  String _tempUnits() {
    return config.controller.temperatureUnits.unit;
  }
}

class CourseOverGroundBox extends _DoubleValueBox {
  static const String sid = 'course-over-ground';
  @override
  String get id => sid;

  CourseOverGroundBox(config, {super.key}) : super(config, 'COG', 'navigation.courseOverGroundTrue', minLen: 3, precision: 0, angle: true) {
    _setup(_convertCOG, _cogUnits);
  }

  double _convertCOG(double cog) {
    return rad2Deg(cog) * 1.0;
  }

  String _cogUnits() {
    return 'deg';
  }
}

class DepthBox extends _DoubleValueBox {
  static const String sid = 'depth';
  @override
  String get id => sid;

  DepthBox(config, {super.key}) : super(config, 'Depth', 'environment.depth.belowSurface', maxValue: 1000.0) {
    _setup(_convertDepth, _depthUnits);
  }

  double _convertDepth(double depth) {
    switch (config.controller.depthUnits) {
      case DepthUnits.m:
        return depth;
      case DepthUnits.ft:
        return depth * 3.28084;
      case DepthUnits.fa:
        return depth * 0.546807;
    }
  }

  String _depthUnits() {
    return config.controller.depthUnits.unit;
  }
}

class SpeedOverGroundBox extends _SpeedBox {
  static const String sid = 'speed-over-ground';
  @override
  String get id => sid;

  SpeedOverGroundBox(config, {super.key}) : super(config, 'SOG', 'navigation.speedOverGround');
}

class SpeedBox extends _SpeedBox {
  static const String sid = 'speed-through-water';
  @override
  String get id => sid;

  SpeedBox(config, {super.key}) : super(config, 'Speed', 'navigation.speedThroughWater');
}

abstract class _SpeedBox extends _DoubleValueBox {

  _SpeedBox(super.config, super.title, super.path, {super.key}) {
    _setup(_convertSpeed, _speedUnits);
  }

  double _convertSpeed(double speed) {
    switch (config.controller.speedUnits) {
      case SpeedUnits.mps:
        return speed;
      case SpeedUnits.kph:
        return speed * 3.6;
      case SpeedUnits.mph:
        return speed * 2.236936;
      case SpeedUnits.kts:
        return speed * 1.943844;
    }
  }

  String _speedUnits() {
    return config.controller.speedUnits.unit;
  }
}

class WindSpeedApparentBox extends _WindSpeedBox {
  static const String sid = 'wind-speed-apparent';
  @override
  String get id => sid;

  WindSpeedApparentBox(config, {super.key}) : super(config, 'AWS', 'environment.wind.speedApparent');
}

class WindSpeedTrueBox extends _WindSpeedBox {
  static const String sid = 'wind-speed-true';
  @override
  String get id => sid;

  WindSpeedTrueBox(config, {super.key}) : super(config, 'TWS', 'environment.wind.speedTrue');
}

abstract class _WindSpeedBox extends _DoubleValueBox {

  _WindSpeedBox(super.config, super.title, super.path, {super.key}) {
    _setup(_convertSpeed, _speedUnits);
  }

  double _convertSpeed(double speed) {
    switch (config.controller.windSpeedUnits) {
      case SpeedUnits.mps:
        return speed;
      case SpeedUnits.kph:
        return speed * 3.6;
      case SpeedUnits.mph:
        return speed * 2.236936;
      case SpeedUnits.kts:
        return speed * 1.943844;
    }
  }

  String _speedUnits() {
    return config.controller.windSpeedUnits.unit;
  }
}

@JsonSerializable()
class _Settings {
  String title;
  String path;
  int precision;
  int minLen;
  double minValue;
  double maxValue;
  bool angle;
  String units;
  double multiplier;

  _Settings({
    this.title = 'title',
    this.path = 'path',
    this.precision = 1,
    this.minLen = 2,
    this.minValue = 0,
    this.maxValue = 100,
    this.angle = false,
    this.units = 'units',
    this.multiplier = 1
  });
}

class CustomDoubleValueBox extends _DoubleValueBox {
  late _Settings _settings;
  String _unitsString;
  double _multiplier;

  CustomDoubleValueBox._init(this._settings, this._unitsString, this._multiplier, super.config, super.title, super.path, {super.precision, super.minLen, super.minValue, super.maxValue, super.angle, super.key}) {
    _setup(_multiply, _getUnits);
  }

  factory CustomDoubleValueBox.fromSettings(config, {key}) {
    _Settings s = _$SettingsFromJson(config.settings);
    return CustomDoubleValueBox._init(s, s.units, s.multiplier, config, s.title, s.path, precision: s.precision, minLen: s.minLen, minValue: s.minValue, maxValue: s.maxValue, angle: s.angle, key: key);
  }

  static String sid = 'custom-double-value';
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

  double _multiply(double value) {
    return value * _multiplier;
  }

  String _getUnits() {
    return _unitsString;
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
      ListTile(
        leading: const Text("Please share your setting to the developers for permanent inclusion."),
        title: IconButton(onPressed: _emailSettings, icon: const Icon(Icons.share)),
      ),
      ListTile(
        leading: const Text("Title:"),
        title: TextFormField(
            initialValue: s.title,
            onChanged: (value) => s.title = value)
      ),
      ListTile(
        leading: const Text("Signalk Path:"),
        title: TextFormField(
            initialValue: s.path,
            onChanged: (value) => s.path = value)
      ),
      ListTile(
          leading: const Text("Units:"),
          title: TextFormField(
              initialValue: s.units,
              onChanged: (value) => s.units = value)
      ),
      ListTile(
        leading: const Text("Multiplier:"),
        title: TextFormField(
            initialValue: s.multiplier.toString(),
            onChanged: (value) => s.multiplier = double.parse(value)),
      ),
      ListTile(
        leading: const Text("Precision:"),
        title: TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            initialValue: s.precision.toString(),
            onChanged: (value) => s.precision = int.parse(value)),
      ),
      ListTile(
        leading: const Text("Min Length:"),
        title: TextFormField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            initialValue: s.minLen.toString(),
            onChanged: (value) => s.minLen = int.parse(value)),
      ),
      ListTile(
        leading: const Text("Min Value:"),
        title: TextFormField(
            initialValue: s.minValue.toString(),
            onChanged: (value) => s.minValue = double.parse(value)),
      ),
      ListTile(
        leading: const Text("Max Value:"),
        title: TextFormField(
            initialValue: s.maxValue.toString(),
            onChanged: (value) => s.maxValue = double.parse(value)),
      ),
      SwitchListTile(title: const Text("Is Angle:"),
          value: s.angle,
          onChanged: (bool value) {
            setState(() {
              s.angle = value;
            });
          }),
    ]);
  }

  //TODO need to check this works.
  static String mailURL = "mailto:feedback@wheretofly.info?subject=Custom%20Box%20Settings";
  static String supportURL = "https://github.com/philseeley/boatinstrument/issues";

  openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _emailSettings() async {
    try {
      await openUrl(mailURL);
    } on PlatformException catch (_){
      openUrl(supportURL);
    }
  }
}

abstract class _DoubleValueBox extends BoxWidget {
  final String title;
  final String path;
  final int precision;
  final int minLen;
  final double? minValue;
  final double? maxValue;
  final bool angle;
  late double Function(double value) _convert;
  late String Function() _units;

  _DoubleValueBox(super.config, this.title, this.path, {this.precision = 1, this.minLen =  2, this.minValue, this.maxValue, this.angle = false, super.key});

  _setup(convert, units) {
    _convert = convert;
    _units = units;
  }

  @override
  State<_DoubleValueBox> createState() => _DoubleValueBoxState();
}

class _DoubleValueBoxState extends State<_DoubleValueBox> {
  double? _value;
  double? _displayValue;

  @override
  void initState() {
    super.initState();
    widget.config.controller.configure(widget, onUpdate: _processData, paths: { widget.path });
  }

  @override
  Widget build(BuildContext context) {
    if(widget.config.editMode) {
      _displayValue = 12.3;
    }

    String valueText = (_displayValue == null) ?
      '-' :
      fmt.format('{:${widget.minLen+(widget.precision > 0?1:0)+widget.precision}.${widget.precision}f}', _displayValue!);

    TextStyle style = Theme.of(context).textTheme.titleMedium!.copyWith(height: 1.0);

    const double pad = 5.0;
    double fontSize = maxFontSize(valueText, style,
          widget.config.constraints.maxHeight - style.fontSize! - (3 * pad),
          widget.config.constraints.maxWidth - (2 * pad));

    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Row(children: [Padding(padding: const EdgeInsets.only(top: pad, left: pad), child: Text('${widget.title} - ${widget._units()}', style: style))]),
      // We need to disable the device text scaling as this interferes with our text scaling.
      Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(pad), child: Text(valueText, textScaler: TextScaler.noScaling,  style: style.copyWith(fontSize: fontSize)))))
    ]);
  }

  _processData(List<Update>? updates) {
    if(updates == null) {
      _displayValue = null;
    } else {
      try {
        double next = (updates[0].value as num).toDouble();

        if ((widget.minValue != null && next < widget.minValue!) ||
            (widget.maxValue != null && next > widget.maxValue!)) {
          _displayValue = null;
        } else {
          if (widget.angle) {
            _value = averageAngle(_value ?? next, next,
                smooth: widget.config.controller.valueSmoothing);
          } else {
            _value = averageDouble(_value ?? next, next,
                smooth: widget.config.controller.valueSmoothing);
          }
          _displayValue = widget._convert(_value!);
        }
      } catch (e) {
        widget.config.controller.l.e("Error converting $updates", error: e);
      }
    }

    if(mounted) {
      setState(() {});
    }
  }
}
