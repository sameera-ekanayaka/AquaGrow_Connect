import 'dart:math' as math;

/// Represents verified hydroponic store, retail supplier, or distribution depot.
class HydroSupplier {
  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String phone;
  final double rating;
  final String openHours;
  final bool isVerified;
  final List<String> featuredProducts;

  const HydroSupplier({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.rating,
    required this.openHours,
    this.isVerified = true,
    required this.featuredProducts,
  });

  /// Computes distance in kilometers from the user's current GPS coordinates
  /// using the spherical Haversine formula.
  double distanceInKmFrom(double userLat, double userLon) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(latitude - userLat);
    final double dLon = _degToRad(longitude - userLon);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(userLat)) *
            math.cos(_degToRad(latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'rating': rating,
      'openHours': openHours,
      'isVerified': isVerified,
      'featuredProducts': featuredProducts,
    };
  }

  /// Curated list of verified hydroponic retailers in Sri Lanka for academic/demo viability.
  static List<HydroSupplier> get defaultSuppliers => const [
        HydroSupplier(
          id: 'sup-col-01',
          name: 'Lanka Hydroponics Hub',
          category: 'Nutrients & Buffers',
          address: 'No. 142, High Level Road, Nugegoda',
          city: 'Colombo',
          latitude: 6.8710,
          longitude: 79.8970,
          phone: '+94 11 282 4500',
          rating: 4.8,
          openHours: '08:30 AM - 06:00 PM',
          isVerified: true,
          featuredProducts: [
            'MasterBlend 4-18-38 Complete',
            'Calcium Nitrate Fertilizer',
            'Magnesium Sulfate (Epsom)',
            'pH Up & pH Down Dosing Liters'
          ],
        ),
        HydroSupplier(
          id: 'sup-col-02',
          name: 'AgriGreen Automation & Media',
          category: 'Rockwool & Growing Media',
          address: '88/2 Baseline Road, Dematagoda',
          city: 'Colombo',
          latitude: 6.9360,
          longitude: 79.8785,
          phone: '+94 11 441 7890',
          rating: 4.7,
          openHours: '09:00 AM - 06:30 PM',
          isVerified: true,
          featuredProducts: [
            'Grodan Rockwool Starter Plugs',
            'Expanded Clay Pebbles (LECA)',
            'Perlite Grade 3 Bulk',
            'Coco Coir Washed Bricks'
          ],
        ),
        HydroSupplier(
          id: 'sup-kan-03',
          name: 'Hill Country Hydro Supplies',
          category: 'LED Lights & Aeration Pumps',
          address: '25 William Gopallawa Mawatha',
          city: 'Kandy',
          latitude: 7.2880,
          longitude: 80.6275,
          phone: '+94 81 223 9912',
          rating: 4.9,
          openHours: '08:00 AM - 05:30 PM',
          isVerified: true,
          featuredProducts: [
            'Samsung LM301B Full Spectrum LED 100W',
            'Submersible Silent 800L/h Pump',
            'Silicone Air Tubing & Airstones',
            '12V Dosing Peristaltic Pumps'
          ],
        ),
        HydroSupplier(
          id: 'sup-gam-04',
          name: 'BioFlora Indoor Agri-Store',
          category: 'Seeds & Genetics',
          address: '12 Negombo Road, Ja-Ela',
          city: 'Gampaha',
          latitude: 7.0750,
          longitude: 79.8920,
          phone: '+94 31 224 5510',
          rating: 4.6,
          openHours: '09:00 AM - 07:00 PM',
          isVerified: true,
          featuredProducts: [
            'Pelleted Rex Butterhead Lettuce Seeds',
            'Genovese Basil Heirloom Pack',
            'Wild Arugula / Rocket Seedlings',
            'Dwarf Pak Choi F1 Hybrid'
          ],
        ),
        HydroSupplier(
          id: 'sup-col-05',
          name: 'Smart Urban Farms Colombo',
          category: 'Full Systems & Sensors',
          address: '77 Galle Road, Kollupitiya',
          city: 'Colombo 03',
          latitude: 6.9030,
          longitude: 79.8510,
          phone: '+94 11 556 1234',
          rating: 4.9,
          openHours: '09:00 AM - 06:00 PM',
          isVerified: true,
          featuredProducts: [
            'Industrial Analog pH Probe Kit',
            'Analog EC / TDS Electrical Conductivity Sensor',
            'Optical Liquid Level Sensor',
            'AquaGrow Modular NFT PVC Channels'
          ],
        ),
      ];
}
