// /home/luisvinatea/Dev/Repos/AeraSync/AeraSync/lib/presentation/widgets/oxygen_demand_results_display.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:clipboard/clipboard.dart';
import '../../core/services/app_state.dart';

class OxygenDemandResultsDisplay extends StatelessWidget {
  const OxygenDemandResultsDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final results = appState.getResults('Oxygen Demand');
        final inputs = appState.getInputs('Oxygen Demand');

        if (results == null || results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Enter values and click Calculate to see results',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final totalOxygenDemand = results['Total Oxygen Demand (kg O₂/h)'] as double;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white.withOpacity(0.9),
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Oxygen Demand Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...results.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _formatValue(entry.value),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                if (entry.key == 'Total Oxygen Demand (kg O₂/h)') ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Color(0xFF1E40AF)),
                                    onPressed: () {
                                      FlutterClipboard.copy(totalOxygenDemand.toStringAsFixed(2))
                                          .then((value) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Total Oxygen Demand copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      });
                                    },
                                    tooltip: 'Copy to clipboard',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadAsCsv(inputs!, results),
                      icon: const Icon(Icons.download, size: 32),
                      label: const Text('Download as CSV (only values)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  void _downloadAsCsv(Map<String, dynamic> inputs, Map<String, dynamic> results) {
    final combinedData = <String, dynamic>{};
    inputs.forEach((key, value) => combinedData['Input: $key'] = value);
    results.forEach((key, value) => combinedData['Result: $key'] = value);

    final csvRows = <String>['"Category","Value"'];
    combinedData.forEach((key, value) {
      final escapedKey = key.replaceAll('"', '""');
      final escapedValue = _formatValue(value).replaceAll('"', '""');
      csvRows.add('"$escapedKey","$escapedValue"');
    });

    final csvContent = csvRows.join('\n');
    final blob = html.Blob([csvContent], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', 'aerasync_oxygen_demand_${DateTime.now().toIso8601String()}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}