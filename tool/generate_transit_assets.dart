// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

final _root = Directory.current.path.endsWith('tool')
    ? Directory.current.parent
    : Directory.current;

final _transitRoot = Directory(
  '${_root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}transit${Platform.pathSeparator}Canada',
);

const _goTransit = <String, List<(String, double, double)>>{
  'Lakeshore West': [
    ('Union GO', 43.6453, -79.3806),
    ('Exhibition GO', 43.6359, -79.4187),
    ('Mimico GO', 43.6172, -79.4946),
    ('Long Branch GO', 43.5910, -79.5400),
    ('Port Credit GO', 43.5534, -79.5855),
    ('Clarkson GO', 43.5232, -79.6338),
    ('Oakville GO', 43.4553, -79.6829),
    ('Bronte GO', 43.4039, -79.7589),
    ('Appleby GO', 43.3811, -79.7624),
    ('Burlington GO', 43.3416, -79.8094),
    ('Aldershot GO', 43.3138, -79.8550),
    ('West Harbour GO', 43.2650, -79.8672),
    ('Confederation GO', 43.2183, -79.8628),
    ('Centennial GO', 43.2189, -79.7380),
    ('St. Catharines GO', 43.1478, -79.2557),
    ('Niagara Falls GO', 43.1099, -79.0613),
  ],
  'Lakeshore East': [
    ('Union GO', 43.6453, -79.3806),
    ('Danforth GO', 43.6905, -79.3005),
    ('Scarborough GO', 43.7244, -79.2482),
    ('Eglinton GO', 43.7311, -79.1944),
    ('Guildwood GO', 43.7528, -79.1943),
    ('Rouge Hill GO', 43.8047, -79.1359),
    ('Pickering GO', 43.8357, -79.0887),
    ('Ajax GO', 43.8503, -79.0404),
    ('Whitby GO', 43.8710, -78.9400),
    ('Oshawa GO', 43.8676, -78.8865),
  ],
  'Milton': [
    ('Union GO', 43.6453, -79.3806),
    ('Exhibition GO', 43.6359, -79.4187),
    ('Cooksville GO', 43.5820, -79.6230),
    ('Erindale GO', 43.5630, -79.6680),
    ('Streetsville GO', 43.5870, -79.7180),
    ('Meadowvale GO', 43.5940, -79.7580),
    ('Lisgar GO', 43.5930, -79.7860),
    ('Milton GO', 43.5130, -79.8670),
  ],
  'Kitchener': [
    ('Union GO', 43.6453, -79.3806),
    ('Bloor GO', 43.6569, -79.4500),
    ('Weston GO', 43.6990, -79.5161),
    ('Etobicoke North GO', 43.7060, -79.5760),
    ('Malton GO', 43.7040, -79.6350),
    ('Brampton GO', 43.6815, -79.7630),
    ('Mount Pleasant GO', 43.6620, -79.8180),
    ('Georgetown GO', 43.6510, -79.9140),
    ('Acton GO', 43.6348, -80.0405),
    ('Guelph Central GO', 43.5440, -80.2490),
    ('Kitchener GO', 43.4555, -80.4930),
  ],
  'Barrie': [
    ('Union GO', 43.6453, -79.3806),
    ('Downsview Park GO', 43.7505, -79.4860),
    ('York University GO', 43.7749, -79.4996),
    ('Rutherford GO', 43.8200, -79.5060),
    ('Maple GO', 43.8430, -79.5200),
    ('Aurora GO', 43.9980, -79.4600),
    ('Newmarket GO', 44.0580, -79.4610),
    ('East Gwillimbury GO', 44.0890, -79.4690),
    ('Bradford GO', 44.1060, -79.5430),
    ('Barrie South GO', 44.3600, -79.6700),
    ('Allandale Waterfront GO', 44.3890, -79.6910),
  ],
  'Stouffville': [
    ('Union GO', 43.6453, -79.3806),
    ('Kennedy GO', 43.7348, -79.2647),
    ('Agincourt GO', 43.7976, -79.2720),
    ('Milliken GO', 43.8255, -79.2810),
    ('Unionville GO', 43.8630, -79.2890),
    ('Centennial GO', 43.8880, -79.2980),
    ('Markham GO', 43.9010, -79.3180),
    ('Mount Joy GO', 43.9170, -79.3180),
    ('Stouffville GO', 43.9710, -79.2590),
    ('Lincolnville GO', 44.0170, -79.2020),
  ],
  'Richmond Hill': [
    ('Union GO', 43.6453, -79.3806),
    ('Oriole GO', 43.7780, -79.3870),
    ('Old Cummer GO', 43.7980, -79.3640),
    ('Langstaff GO', 43.8210, -79.4260),
    ('Richmond Hill GO', 43.8480, -79.4260),
  ],
};

const _ttc = <String, List<(String, double, double)>>{
  'Line 1': [
    ('Finch Station', 43.7817, -79.4157),
    ('North York Centre Station', 43.7682, -79.4130),
    ('Sheppard-Yonge Station', 43.7614, -79.4109),
    ('York Mills Station', 43.7443, -79.4090),
    ('Lawrence Station', 43.7246, -79.3930),
    ('Eglinton Station', 43.7067, -79.3987),
    ('Davisville Station', 43.6977, -79.3965),
    ('St Clair Station', 43.6888, -79.3938),
    ('Summerhill Station', 43.6820, -79.3905),
    ('Rosedale Station', 43.6742, -79.3805),
    ('Bloor-Yonge Station', 43.6705, -79.3866),
    ('Wellesley Station', 43.6651, -79.3851),
    ('College Station', 43.6617, -79.3840),
    ('Dundas Station', 43.6564, -79.3804),
    ('Queen Station', 43.6523, -79.3798),
    ('King Station', 43.6489, -79.3787),
    ('Union Station', 43.6455, -79.3806),
    ('St Andrew Station', 43.6476, -79.3867),
    ('Osgoode Station', 43.6508, -79.3867),
    ('St Patrick Station', 43.6546, -79.3867),
    ("Queen's Park Station", 43.6579, -79.3888),
    ('Museum Station', 43.6605, -79.3900),
    ('St George Station', 43.6682, -79.3997),
    ('Spadina Station', 43.6650, -79.4033),
    ('Dupont Station', 43.6503, -79.4057),
    ('St Clair West Station', 43.6784, -79.4107),
    ('Dufferin Station', 43.6570, -79.4358),
    ('Keele Station', 43.6555, -79.4580),
    ('Dundas West Station', 43.6533, -79.4640),
    ('Lansdowne Station', 43.6490, -79.4750),
    ('Glencairn Station', 43.6370, -79.4890),
    ('Lawrence West Station', 43.6250, -79.4970),
    ('Yorkdale Station', 43.6150, -79.5060),
    ('Wilson Station', 43.7347, -79.4502),
    ('Sheppard West Station', 43.7246, -79.4771),
    ('Downsview Park Station', 43.7379, -79.4830),
    ('Finch West Station', 43.7649, -79.4859),
    ('York University Station', 43.7749, -79.4996),
    ('Pioneer Village Station', 43.8165, -79.5164),
    ('Highway 407 Station', 43.8048, -79.5246),
    ('Vaughan Metropolitan Centre Station', 43.7949, -79.5273),
  ],
  'Line 2': [
    ('Kennedy Station', 43.7326, -79.2642),
    ('Warden Station', 43.7106, -79.2796),
    ('Victoria Park Station', 43.6893, -79.2928),
    ('Main Street Station', 43.6789, -79.3524),
    ('Woodbine Station', 43.6860, -79.3150),
    ('Coxwell Station', 43.6760, -79.3370),
    ('Greenwood Station', 43.6680, -79.3470),
    ('Donlands Station', 43.6650, -79.3570),
    ('Pape Station', 43.6640, -79.3640),
    ('Chester Station', 43.6620, -79.3700),
    ('Broadview Station', 43.6600, -79.3760),
    ('Castle Frank Station', 43.6590, -79.3820),
    ('Sherbourne Station', 43.6610, -79.3880),
    ('Bloor-Yonge Station', 43.6705, -79.3866),
    ('Bay Station', 43.6620, -79.3820),
    ('St George Station', 43.6682, -79.3997),
    ('Spadina Station', 43.6650, -79.4033),
    ('Bathurst Station', 43.6560, -79.4060),
    ('Christie Station', 43.6530, -79.4180),
    ('Ossington Station', 43.6510, -79.4260),
    ('Dufferin Station', 43.6570, -79.4358),
    ('Keele Station', 43.6555, -79.4580),
    ('High Park Station', 43.6460, -79.4660),
    ('Runnymede Station', 43.6420, -79.4760),
    ('Jane Station', 43.6350, -79.4860),
    ('Old Mill Station', 43.6280, -79.4960),
    ('Royal York Station', 43.6200, -79.5060),
    ('Islington Station', 43.6120, -79.5160),
    ('Kipling Station', 43.6020, -79.5260),
  ],
  'Line 4': [
    ('Sheppard-Yonge Station', 43.7614, -79.4109),
    ('Bayview Station', 43.7680, -79.3920),
    ('Bessarion Station', 43.7690, -79.3790),
    ('Leslie Station', 43.7700, -79.3650),
    ('Don Mills Station', 43.7750, -79.3460),
  ],
};

Future<void> main() async {
  for (final entry in _goTransit.entries) {
    await _writeLine('Canada', 'GO Transit', entry.key, entry.value);
  }
  for (final entry in _ttc.entries) {
    await _writeLine('Canada', 'TTC', entry.key, entry.value);
  }
  print('Done.');
}

Future<void> _writeLine(
  String country,
  String system,
  String lineName,
  List<(String, double, double)> stations,
) async {
  final systemDir = Directory(
    '${_transitRoot.path}${Platform.pathSeparator}${system.replaceAll(' ', '_')}',
  );
  await systemDir.create(recursive: true);

  final payload = {
    'country': country,
    'transitSystem': system,
    'lineName': lineName,
    'stations': [
      for (var i = 0; i < stations.length; i++)
        {
          'name': stations[i].$1,
          'latitude': stations[i].$2,
          'longitude': stations[i].$3,
          'stationOrder': i + 1,
        },
    ],
  };

  final fileName = '${lineName.replaceAll(' ', '_')}.json';
  final file = File('${systemDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
  print('Wrote ${file.path} (${stations.length} stations)');
}
