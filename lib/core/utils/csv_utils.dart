import '../../data/database/daos/time_entry_dao.dart';

/// Export all time entries to CSV.
Future<String> exportToCsv(TimeEntryDao dao) async {
  final entries = await dao.getAllEntries();
  final buffer = StringBuffer();

  // Header
  buffer.writeln(
      'id,issue_id,issue_identifier,issue_title,team_name,project_name,'
      'start_time,end_time,duration_seconds,is_manual');

  for (final entry in entries) {
    buffer.writeln(
      '${entry.id},'
      '${_escapeCsv(entry.issueId)},'
      '${_escapeCsv(entry.issueIdentifier)},'
      '${_escapeCsv(entry.issueTitle)},'
      '${_escapeCsv(entry.teamName ?? '')},'
      '${_escapeCsv(entry.projectName ?? '')},'
      '${entry.startTime.toIso8601String()},'
      '${entry.endTime?.toIso8601String() ?? ''},'
      '${entry.durationSeconds ?? ''},'
      '${entry.isManual}',
    );
  }

  return buffer.toString();
}

/// Import time entries from CSV content.
/// Returns the number of entries imported.
Future<int> importFromCsv(TimeEntryDao dao, String csvContent) async {
  final lines = csvContent.split('\n');
  if (lines.length < 2) return 0;

  // Skip header
  int imported = 0;
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;

    final fields = _parseCsvLine(line);
    if (fields.length < 10) continue;

    try {
      final startTime = DateTime.parse(fields[6]);
      final endTime = fields[7].isNotEmpty ? DateTime.parse(fields[7]) : null;
      await dao.addManualEntry(
        issueId: fields[1],
        issueIdentifier: fields[2],
        issueTitle: fields[3],
        teamName: fields[4].isNotEmpty ? fields[4] : null,
        projectName: fields[5].isNotEmpty ? fields[5] : null,
        startTime: startTime,
        endTime: endTime ?? startTime,
      );
      imported++;
    } catch (_) {
      // Skip malformed rows
    }
  }

  return imported;
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var current = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (inQuotes) {
      if (char == '"' && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else if (char == '"') {
        inQuotes = false;
      } else {
        current.write(char);
      }
    } else {
      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        fields.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
  }
  fields.add(current.toString());
  return fields;
}
