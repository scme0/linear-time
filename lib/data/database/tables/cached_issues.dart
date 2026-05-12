import 'package:drift/drift.dart';

class CachedIssues extends Table {
  TextColumn get issueId => text()();
  TextColumn get identifier => text()();
  TextColumn get title => text()();
  TextColumn get teamId => text().nullable()();
  TextColumn get teamName => text().nullable()();
  TextColumn get teamColor => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get projectName => text().nullable()();
  TextColumn get status => text()();
  TextColumn get statusType => text()();
  IntColumn get priority => integer()();
  TextColumn get url => text()();
  TextColumn get assigneeId => text().nullable()();
  TextColumn get assigneeName => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isAssigned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSynced => dateTime()();

  @override
  Set<Column> get primaryKey => {issueId};
}
