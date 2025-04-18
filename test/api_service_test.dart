import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:aerasync/core/services/api_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(client: mockClient);
      registerFallbackValue(Uri.parse('http://127.0.0.1:8000/health'));
    });

    test('ApiService checks health successfully', () async {
      when(() => mockClient.get(Uri.parse('http://127.0.0.1:8000/health')))
          .thenAnswer((_) async => http.Response('OK', 200));

      final result = await apiService.checkHealth();
      expect(result, isTrue);
    });

    test('ApiService compares aerators successfully', () async {
      final inputs = {
        'farm': {
          'area_ha': 1000.0,
          'production_kg_ha_year': 10000.0,
          'cycles_per_year': 3.0,
          'pond_depth_m': 1.0,
        },
        'oxygen': {
          'temperature_c': 31.5,
          'salinity_ppt': 20.0,
          'shrimp_weight_g': 10.0,
          'biomass_kg_ha': 3333.33,
        },
        'aerators': [
          {
            'name': 'Aerator 1',
            'power_hp': 3.0,
            'sotr_kg_o2_h': 1.4,
            'initial_cost_usd': 500.0,
            'durability_years': 2.0,
            'maintenance_usd_year': 65.0,
          },
          {
            'name': 'Aerator 2',
            'power_hp': 3.5,
            'sotr_kg_o2_h': 2.2,
            'initial_cost_usd': 800.0,
            'durability_years': 4.5,
            'maintenance_usd_year': 50.0,
          },
        ],
        'financial': {
          'shrimp_price_usd_kg': 5.0,
          'energy_cost_usd_kwh': 0.05,
          'operating_hours_year': 2920.0,
          'discount_rate_percent': 10.0,
          'inflation_rate_percent': 2.5,
          'analysis_horizon_years': 9,
        },
      };

      when(() => mockClient.post(
            Uri.parse('http://127.0.0.1:8000/compare'),
            headers: {'Content-Type': 'application/json'},
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(
            '{"tod": 10.0, "winnerLabel": "Aerator 1", "aeratorResults": [], "shrimpRespiration": 5.0, "pondRespiration": 3.0, "pondWaterRespiration": 2.0, "pondBottomRespiration": 1.0, "annualRevenue": 1000.0, "apiResults": {}}',
            200,
          ));

      final result = await apiService.compareAerators(inputs);
      expect(result['winnerLabel'], isNotNull);
      expect(result['tod'], isA<double>());
      expect(result['aeratorResults'], isA<List>());
    });
  });
}