import 'package:drift/drift.dart';

class TimeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get issueId => text()();
  TextColumn get issueIdentifier => text()();
  TextColumn get issueTitle => text()();
  TextColumn get teamName => text().nullable()();
  TextColumn get projectName => text().nullable()();
  TextColumn get teamColor => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
}
