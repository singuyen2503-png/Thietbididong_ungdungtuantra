import 'dart:math' as math;

class GeoUtils {
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000;
    final double phi1 = lat1 * math.pi / 180;
    final double phi2 = lat2 * math.pi / 180;
    final double deltaPhi = (lat2 - lat1) * math.pi / 180;
    final double deltaLambda = (lon2 - lon1) * math.pi / 180;

    final double a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}
