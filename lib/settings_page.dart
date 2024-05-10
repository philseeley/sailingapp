part of 'boatinstrument_controller.dart';

class SettingsPage extends StatefulWidget {
  final BoatInstrumentController _controller;

  const SettingsPage(this._controller, {super.key});

  @override
  createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    _Settings settings = widget._controller._settings!;

    List<Widget> list = [
      ListTile(
        leading: const Text("Value Smoothing:"),
        title: Slider(
            min: 1,
            max: 20,
            divisions: 20,
            value: settings.valueSmoothing.toDouble(),
            label: "${settings.valueSmoothing.toInt()}",
            onChanged: (double value) {
              setState(() {
                settings.valueSmoothing = value.toInt();
              });
            }),
      ),
      ListTile(
          leading: const Text("Signalk Server:"),
          title: TextFormField(
              initialValue: settings.signalkServer,
              onChanged: (value) => settings.signalkServer = value)
      ),
      SwitchListTile(title: const Text("Wraparound page change:"),
          value: settings.wrapPages,
          onChanged: (bool value) {
            setState(() {
              settings.wrapPages = value;
            });
          }),
      ListTile(
          leading: const Text("Distance:  "),
          title: _distanceRadioList()
      ),
      ListTile(
          leading: const Text("Speed:     "),
          title: _speedRadioList()
      ),
      ListTile(
          leading: const Text("Wind Speed:"),
          title: _windSpeedRadioList()
      ),
      ListTile(
          leading: const Text("Depth:     "),
          title: _depthRadioList()
      ),
      ListTile(
          leading: const Text('Pages:'),
          title: IconButton(icon: const Icon(Icons.add), onPressed: _addPage,)
      ),
    ];

    for(int p = 0; p < settings.pages.length; ++p) {
      _Page page = settings.pages[p];

      list.add(ListTile(
        leading: IconButton(icon: const Icon(Icons.edit), onPressed: () {_editPage(page);}),
        title: TextFormField(
            initialValue: page.name,
            onChanged: (value) => page.name = value),
        trailing: (p == 0) ? null : IconButton(icon: const Icon(Icons.delete), onPressed: () {_deletePage(p);})
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          IconButton(icon: const Icon(Icons.notes),onPressed:  _showLog)
        ],
      ),
      body: ListView(children: list)
    );
  }

  Row _distanceRadioList() {
    List<Widget> l = [];
    for(var v in DistanceUnits.values) {
      l.add(Radio(
          value: v,
          groupValue: widget._controller._settings?.distanceUnits,
          onChanged: (value) { setState(() { widget._controller._settings?.distanceUnits = value!;});}));
      l.add(Text(v.displayName));
    }
    return Row(children: l);
  }

  Row _speedRadioList() {
    List<Widget> l = [];
    for(var v in SpeedUnits.values) {
      l.add(Radio(
          value: v,
          groupValue: widget._controller._settings?.speedUnits,
          onChanged: (value) { setState(() { widget._controller._settings?.speedUnits = value!;});}));
      l.add(Text(v.displayName));
    }
    return Row(children: l);
  }

  Row _windSpeedRadioList() {
    List<Widget> l = [];
    for(var v in SpeedUnits.values) {
      l.add(Radio(
          value: v,
          groupValue: widget._controller._settings?.windSpeedUnits,
          onChanged: (value) { setState(() { widget._controller._settings?.windSpeedUnits = value!;});}));
      l.add(Text(v.displayName));
    }
    return Row(children: l);
  }

  Row _depthRadioList() {
    List<Widget> l = [];
    for(var v in DepthUnits.values) {
      l.add(Radio(
          value: v,
          groupValue: widget._controller._settings?.depthUnits,
          onChanged: (value) { setState(() { widget._controller._settings?.depthUnits = value!;});}));
      l.add(Text(v.displayName));
    }
    return Row(children: l);
  }

  void _showLog () async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) {
      return LogDisplay(widget._controller);
    }));

    setState(() {});
  }

  void _addPage() {
    setState(() {
      widget._controller._settings?.pages.add(_Page._newPage());
    });
  }

  void _editPage (_Page page) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) {
      return _EditPage(widget._controller, page);
    }));
  }

  void _deletePage(int papeNum) {
    setState(() {
      widget._controller._settings?.pages.removeAt(papeNum);
    });
  }
}
