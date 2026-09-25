import 'package:flutter/material.dart';

import '../models/benchmark_metric.dart';

/// Side-by-side summary for completed age and education benchmark runs.
class BenchmarkComparisonScreen extends StatelessWidget {
  const BenchmarkComparisonScreen({
    super.key,
    required this.resultsByProofType,
  });

  final Map<String, List<BenchmarkMetric>> resultsByProofType;

  _Summary? _summaryFor(String type) {
    final metrics = resultsByProofType[type];
    return metrics == null || metrics.isEmpty ? null : _Summary(metrics);
  }

  @override
  Widget build(BuildContext context) {
    final age = _summaryFor('age');
    final education = _summaryFor('education');
    return Scaffold(
      appBar: AppBar(title: const Text('Benchmark comparison')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'AGE VS EDUCATION',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compare completed 50-cycle runs on this device. Results are kept only while this dashboard is open.',
          ),
          const SizedBox(height: 20),
          _ComparisonTable(age: age, education: education),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Research target',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Average Groth16 proving time should remain below 2.0 seconds.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_targetStatus('Age', age)}\n${_targetStatus('Education', education)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _targetStatus(String label, _Summary? summary) {
    if (summary == null) {
      return '$label: run its benchmark to assess the target.';
    }
    final meetsTarget = summary.proofMs < 2000;
    return '$label: ${summary.proofMs.toStringAsFixed(1)} ms — ${meetsTarget ? 'meets' : 'does not meet'} the < 2.0 s target.';
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.age, required this.education});
  final _Summary? age;
  final _Summary? education;
  String _value(_Summary? summary, String Function(_Summary) select) =>
      summary == null ? '—' : select(summary);

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: DataTable(
      columnSpacing: 14,
      columns: const [
        DataColumn(label: Text('Metric')),
        DataColumn(label: Text('Age')),
        DataColumn(label: Text('Education')),
      ],
      rows: [
        DataRow(
          cells: [
            DataCell(Text('Cycles')),
            DataCell(Text(_value(age, (s) => '${s.cycles}'))),
            DataCell(Text(_value(education, (s) => '${s.cycles}'))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Proof')),
            DataCell(
              Text(_value(age, (s) => '${s.proofMs.toStringAsFixed(1)} ms')),
            ),
            DataCell(
              Text(
                _value(education, (s) => '${s.proofMs.toStringAsFixed(1)} ms'),
              ),
            ),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Verify')),
            DataCell(
              Text(_value(age, (s) => '${s.verifyMs.toStringAsFixed(1)} ms')),
            ),
            DataCell(
              Text(
                _value(education, (s) => '${s.verifyMs.toStringAsFixed(1)} ms'),
              ),
            ),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Base85')),
            DataCell(Text(_value(age, (s) => '${s.compressedBytes} B'))),
            DataCell(Text(_value(education, (s) => '${s.compressedBytes} B'))),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('Peak RAM')),
            DataCell(
              Text(_value(age, (s) => '${s.memoryMb.toStringAsFixed(1)} MB')),
            ),
            DataCell(
              Text(
                _value(education, (s) => '${s.memoryMb.toStringAsFixed(1)} MB'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Summary {
  _Summary(List<BenchmarkMetric> metrics)
    : cycles = metrics.length,
      proofMs = _average(metrics.map((m) => m.proofTimeMs)),
      verifyMs = _average(metrics.map((m) => m.verifyTimeMs)),
      compressedBytes = _average(
        metrics.map((m) => m.compressedPayloadBytes),
      ).round(),
      memoryMb = _average(metrics.map((m) => m.peakMemoryMb));
  final int cycles;
  final double proofMs;
  final double verifyMs;
  final int compressedBytes;
  final double memoryMb;
  static double _average(Iterable<num> values) =>
      values.fold<double>(0, (sum, value) => sum + value) / values.length;
}
