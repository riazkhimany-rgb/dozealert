import 'transit_agency.dart';
import 'transit_route.dart';
import 'transit_stop.dart';

class AgencyDetectionResult {
  const AgencyDetectionResult({
    required this.agency,
    this.route,
    this.stop,
  });

  final TransitAgency agency;
  final TransitRoute? route;
  final TransitStop? stop;
}
