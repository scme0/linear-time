// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TimeEntriesTable extends TimeEntries
    with TableInfo<$TimeEntriesTable, TimeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _issueIdMeta = const VerificationMeta(
    'issueId',
  );
  @override
  late final GeneratedColumn<String> issueId = GeneratedColumn<String>(
    'issue_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueIdentifierMeta = const VerificationMeta(
    'issueIdentifier',
  );
  @override
  late final GeneratedColumn<String> issueIdentifier = GeneratedColumn<String>(
    'issue_identifier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issueTitleMeta = const VerificationMeta(
    'issueTitle',
  );
  @override
  late final GeneratedColumn<String> issueTitle = GeneratedColumn<String>(
    'issue_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamNameMeta = const VerificationMeta(
    'teamName',
  );
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
    'team_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamColorMeta = const VerificationMeta(
    'teamColor',
  );
  @override
  late final GeneratedColumn<String> teamColor = GeneratedColumn<String>(
    'team_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isManualMeta = const VerificationMeta(
    'isManual',
  );
  @override
  late final GeneratedColumn<bool> isManual = GeneratedColumn<bool>(
    'is_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    issueId,
    issueIdentifier,
    issueTitle,
    teamName,
    projectName,
    teamColor,
    startTime,
    endTime,
    durationSeconds,
    isManual,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('issue_id')) {
      context.handle(
        _issueIdMeta,
        issueId.isAcceptableOrUnknown(data['issue_id']!, _issueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_issueIdMeta);
    }
    if (data.containsKey('issue_identifier')) {
      context.handle(
        _issueIdentifierMeta,
        issueIdentifier.isAcceptableOrUnknown(
          data['issue_identifier']!,
          _issueIdentifierMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_issueIdentifierMeta);
    }
    if (data.containsKey('issue_title')) {
      context.handle(
        _issueTitleMeta,
        issueTitle.isAcceptableOrUnknown(data['issue_title']!, _issueTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_issueTitleMeta);
    }
    if (data.containsKey('team_name')) {
      context.handle(
        _teamNameMeta,
        teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('team_color')) {
      context.handle(
        _teamColorMeta,
        teamColor.isAcceptableOrUnknown(data['team_color']!, _teamColorMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_manual')) {
      context.handle(
        _isManualMeta,
        isManual.isAcceptableOrUnknown(data['is_manual']!, _isManualMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      issueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_id'],
      )!,
      issueIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_identifier'],
      )!,
      issueTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_title'],
      )!,
      teamName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_name'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      teamColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_color'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      isManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_manual'],
      )!,
    );
  }

  @override
  $TimeEntriesTable createAlias(String alias) {
    return $TimeEntriesTable(attachedDatabase, alias);
  }
}

class TimeEntry extends DataClass implements Insertable<TimeEntry> {
  final int id;
  final String issueId;
  final String issueIdentifier;
  final String issueTitle;
  final String? teamName;
  final String? projectName;
  final String? teamColor;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final bool isManual;
  const TimeEntry({
    required this.id,
    required this.issueId,
    required this.issueIdentifier,
    required this.issueTitle,
    this.teamName,
    this.projectName,
    this.teamColor,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.isManual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['issue_id'] = Variable<String>(issueId);
    map['issue_identifier'] = Variable<String>(issueIdentifier);
    map['issue_title'] = Variable<String>(issueTitle);
    if (!nullToAbsent || teamName != null) {
      map['team_name'] = Variable<String>(teamName);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    if (!nullToAbsent || teamColor != null) {
      map['team_color'] = Variable<String>(teamColor);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['is_manual'] = Variable<bool>(isManual);
    return map;
  }

  TimeEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimeEntriesCompanion(
      id: Value(id),
      issueId: Value(issueId),
      issueIdentifier: Value(issueIdentifier),
      issueTitle: Value(issueTitle),
      teamName: teamName == null && nullToAbsent
          ? const Value.absent()
          : Value(teamName),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      teamColor: teamColor == null && nullToAbsent
          ? const Value.absent()
          : Value(teamColor),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      isManual: Value(isManual),
    );
  }

  factory TimeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeEntry(
      id: serializer.fromJson<int>(json['id']),
      issueId: serializer.fromJson<String>(json['issueId']),
      issueIdentifier: serializer.fromJson<String>(json['issueIdentifier']),
      issueTitle: serializer.fromJson<String>(json['issueTitle']),
      teamName: serializer.fromJson<String?>(json['teamName']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      teamColor: serializer.fromJson<String?>(json['teamColor']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      isManual: serializer.fromJson<bool>(json['isManual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'issueId': serializer.toJson<String>(issueId),
      'issueIdentifier': serializer.toJson<String>(issueIdentifier),
      'issueTitle': serializer.toJson<String>(issueTitle),
      'teamName': serializer.toJson<String?>(teamName),
      'projectName': serializer.toJson<String?>(projectName),
      'teamColor': serializer.toJson<String?>(teamColor),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'isManual': serializer.toJson<bool>(isManual),
    };
  }

  TimeEntry copyWith({
    int? id,
    String? issueId,
    String? issueIdentifier,
    String? issueTitle,
    Value<String?> teamName = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    Value<String?> teamColor = const Value.absent(),
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    bool? isManual,
  }) => TimeEntry(
    id: id ?? this.id,
    issueId: issueId ?? this.issueId,
    issueIdentifier: issueIdentifier ?? this.issueIdentifier,
    issueTitle: issueTitle ?? this.issueTitle,
    teamName: teamName.present ? teamName.value : this.teamName,
    projectName: projectName.present ? projectName.value : this.projectName,
    teamColor: teamColor.present ? teamColor.value : this.teamColor,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    isManual: isManual ?? this.isManual,
  );
  TimeEntry copyWithCompanion(TimeEntriesCompanion data) {
    return TimeEntry(
      id: data.id.present ? data.id.value : this.id,
      issueId: data.issueId.present ? data.issueId.value : this.issueId,
      issueIdentifier: data.issueIdentifier.present
          ? data.issueIdentifier.value
          : this.issueIdentifier,
      issueTitle: data.issueTitle.present
          ? data.issueTitle.value
          : this.issueTitle,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      teamColor: data.teamColor.present ? data.teamColor.value : this.teamColor,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      isManual: data.isManual.present ? data.isManual.value : this.isManual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntry(')
          ..write('id: $id, ')
          ..write('issueId: $issueId, ')
          ..write('issueIdentifier: $issueIdentifier, ')
          ..write('issueTitle: $issueTitle, ')
          ..write('teamName: $teamName, ')
          ..write('projectName: $projectName, ')
          ..write('teamColor: $teamColor, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isManual: $isManual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    issueId,
    issueIdentifier,
    issueTitle,
    teamName,
    projectName,
    teamColor,
    startTime,
    endTime,
    durationSeconds,
    isManual,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeEntry &&
          other.id == this.id &&
          other.issueId == this.issueId &&
          other.issueIdentifier == this.issueIdentifier &&
          other.issueTitle == this.issueTitle &&
          other.teamName == this.teamName &&
          other.projectName == this.projectName &&
          other.teamColor == this.teamColor &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.durationSeconds == this.durationSeconds &&
          other.isManual == this.isManual);
}

class TimeEntriesCompanion extends UpdateCompanion<TimeEntry> {
  final Value<int> id;
  final Value<String> issueId;
  final Value<String> issueIdentifier;
  final Value<String> issueTitle;
  final Value<String?> teamName;
  final Value<String?> projectName;
  final Value<String?> teamColor;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<int?> durationSeconds;
  final Value<bool> isManual;
  const TimeEntriesCompanion({
    this.id = const Value.absent(),
    this.issueId = const Value.absent(),
    this.issueIdentifier = const Value.absent(),
    this.issueTitle = const Value.absent(),
    this.teamName = const Value.absent(),
    this.projectName = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isManual = const Value.absent(),
  });
  TimeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String issueId,
    required String issueIdentifier,
    required String issueTitle,
    this.teamName = const Value.absent(),
    this.projectName = const Value.absent(),
    this.teamColor = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.isManual = const Value.absent(),
  }) : issueId = Value(issueId),
       issueIdentifier = Value(issueIdentifier),
       issueTitle = Value(issueTitle),
       startTime = Value(startTime);
  static Insertable<TimeEntry> custom({
    Expression<int>? id,
    Expression<String>? issueId,
    Expression<String>? issueIdentifier,
    Expression<String>? issueTitle,
    Expression<String>? teamName,
    Expression<String>? projectName,
    Expression<String>? teamColor,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<int>? durationSeconds,
    Expression<bool>? isManual,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (issueId != null) 'issue_id': issueId,
      if (issueIdentifier != null) 'issue_identifier': issueIdentifier,
      if (issueTitle != null) 'issue_title': issueTitle,
      if (teamName != null) 'team_name': teamName,
      if (projectName != null) 'project_name': projectName,
      if (teamColor != null) 'team_color': teamColor,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (isManual != null) 'is_manual': isManual,
    });
  }

  TimeEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? issueId,
    Value<String>? issueIdentifier,
    Value<String>? issueTitle,
    Value<String?>? teamName,
    Value<String?>? projectName,
    Value<String?>? teamColor,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<int?>? durationSeconds,
    Value<bool>? isManual,
  }) {
    return TimeEntriesCompanion(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      issueIdentifier: issueIdentifier ?? this.issueIdentifier,
      issueTitle: issueTitle ?? this.issueTitle,
      teamName: teamName ?? this.teamName,
      projectName: projectName ?? this.projectName,
      teamColor: teamColor ?? this.teamColor,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isManual: isManual ?? this.isManual,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (issueId.present) {
      map['issue_id'] = Variable<String>(issueId.value);
    }
    if (issueIdentifier.present) {
      map['issue_identifier'] = Variable<String>(issueIdentifier.value);
    }
    if (issueTitle.present) {
      map['issue_title'] = Variable<String>(issueTitle.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (teamColor.present) {
      map['team_color'] = Variable<String>(teamColor.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (isManual.present) {
      map['is_manual'] = Variable<bool>(isManual.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('issueId: $issueId, ')
          ..write('issueIdentifier: $issueIdentifier, ')
          ..write('issueTitle: $issueTitle, ')
          ..write('teamName: $teamName, ')
          ..write('projectName: $projectName, ')
          ..write('teamColor: $teamColor, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('isManual: $isManual')
          ..write(')'))
        .toString();
  }
}

class $CachedIssuesTable extends CachedIssues
    with TableInfo<$CachedIssuesTable, CachedIssue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedIssuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _issueIdMeta = const VerificationMeta(
    'issueId',
  );
  @override
  late final GeneratedColumn<String> issueId = GeneratedColumn<String>(
    'issue_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identifierMeta = const VerificationMeta(
    'identifier',
  );
  @override
  late final GeneratedColumn<String> identifier = GeneratedColumn<String>(
    'identifier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamNameMeta = const VerificationMeta(
    'teamName',
  );
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
    'team_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _teamColorMeta = const VerificationMeta(
    'teamColor',
  );
  @override
  late final GeneratedColumn<String> teamColor = GeneratedColumn<String>(
    'team_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectNameMeta = const VerificationMeta(
    'projectName',
  );
  @override
  late final GeneratedColumn<String> projectName = GeneratedColumn<String>(
    'project_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusTypeMeta = const VerificationMeta(
    'statusType',
  );
  @override
  late final GeneratedColumn<String> statusType = GeneratedColumn<String>(
    'status_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assigneeIdMeta = const VerificationMeta(
    'assigneeId',
  );
  @override
  late final GeneratedColumn<String> assigneeId = GeneratedColumn<String>(
    'assignee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assigneeNameMeta = const VerificationMeta(
    'assigneeName',
  );
  @override
  late final GeneratedColumn<String> assigneeName = GeneratedColumn<String>(
    'assignee_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAssignedMeta = const VerificationMeta(
    'isAssigned',
  );
  @override
  late final GeneratedColumn<bool> isAssigned = GeneratedColumn<bool>(
    'is_assigned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_assigned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncedMeta = const VerificationMeta(
    'lastSynced',
  );
  @override
  late final GeneratedColumn<DateTime> lastSynced = GeneratedColumn<DateTime>(
    'last_synced',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    issueId,
    identifier,
    title,
    teamId,
    teamName,
    teamColor,
    projectId,
    projectName,
    status,
    statusType,
    priority,
    url,
    assigneeId,
    assigneeName,
    isDeleted,
    isAssigned,
    lastSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_issues';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedIssue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('issue_id')) {
      context.handle(
        _issueIdMeta,
        issueId.isAcceptableOrUnknown(data['issue_id']!, _issueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_issueIdMeta);
    }
    if (data.containsKey('identifier')) {
      context.handle(
        _identifierMeta,
        identifier.isAcceptableOrUnknown(data['identifier']!, _identifierMeta),
      );
    } else if (isInserting) {
      context.missing(_identifierMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('team_name')) {
      context.handle(
        _teamNameMeta,
        teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta),
      );
    }
    if (data.containsKey('team_color')) {
      context.handle(
        _teamColorMeta,
        teamColor.isAcceptableOrUnknown(data['team_color']!, _teamColorMeta),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('project_name')) {
      context.handle(
        _projectNameMeta,
        projectName.isAcceptableOrUnknown(
          data['project_name']!,
          _projectNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('status_type')) {
      context.handle(
        _statusTypeMeta,
        statusType.isAcceptableOrUnknown(data['status_type']!, _statusTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_statusTypeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('assignee_id')) {
      context.handle(
        _assigneeIdMeta,
        assigneeId.isAcceptableOrUnknown(data['assignee_id']!, _assigneeIdMeta),
      );
    }
    if (data.containsKey('assignee_name')) {
      context.handle(
        _assigneeNameMeta,
        assigneeName.isAcceptableOrUnknown(
          data['assignee_name']!,
          _assigneeNameMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('is_assigned')) {
      context.handle(
        _isAssignedMeta,
        isAssigned.isAcceptableOrUnknown(data['is_assigned']!, _isAssignedMeta),
      );
    }
    if (data.containsKey('last_synced')) {
      context.handle(
        _lastSyncedMeta,
        lastSynced.isAcceptableOrUnknown(data['last_synced']!, _lastSyncedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {issueId};
  @override
  CachedIssue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedIssue(
      issueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issue_id'],
      )!,
      identifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identifier'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      ),
      teamName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_name'],
      ),
      teamColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_color'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      projectName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      statusType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_type'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      assigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_id'],
      ),
      assigneeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_name'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      isAssigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_assigned'],
      )!,
      lastSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced'],
      )!,
    );
  }

  @override
  $CachedIssuesTable createAlias(String alias) {
    return $CachedIssuesTable(attachedDatabase, alias);
  }
}

class CachedIssue extends DataClass implements Insertable<CachedIssue> {
  final String issueId;
  final String identifier;
  final String title;
  final String? teamId;
  final String? teamName;
  final String? teamColor;
  final String? projectId;
  final String? projectName;
  final String status;
  final String statusType;
  final int priority;
  final String url;
  final String? assigneeId;
  final String? assigneeName;
  final bool isDeleted;
  final bool isAssigned;
  final DateTime lastSynced;
  const CachedIssue({
    required this.issueId,
    required this.identifier,
    required this.title,
    this.teamId,
    this.teamName,
    this.teamColor,
    this.projectId,
    this.projectName,
    required this.status,
    required this.statusType,
    required this.priority,
    required this.url,
    this.assigneeId,
    this.assigneeName,
    required this.isDeleted,
    required this.isAssigned,
    required this.lastSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['issue_id'] = Variable<String>(issueId);
    map['identifier'] = Variable<String>(identifier);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || teamName != null) {
      map['team_name'] = Variable<String>(teamName);
    }
    if (!nullToAbsent || teamColor != null) {
      map['team_color'] = Variable<String>(teamColor);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || projectName != null) {
      map['project_name'] = Variable<String>(projectName);
    }
    map['status'] = Variable<String>(status);
    map['status_type'] = Variable<String>(statusType);
    map['priority'] = Variable<int>(priority);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || assigneeId != null) {
      map['assignee_id'] = Variable<String>(assigneeId);
    }
    if (!nullToAbsent || assigneeName != null) {
      map['assignee_name'] = Variable<String>(assigneeName);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['is_assigned'] = Variable<bool>(isAssigned);
    map['last_synced'] = Variable<DateTime>(lastSynced);
    return map;
  }

  CachedIssuesCompanion toCompanion(bool nullToAbsent) {
    return CachedIssuesCompanion(
      issueId: Value(issueId),
      identifier: Value(identifier),
      title: Value(title),
      teamId: teamId == null && nullToAbsent
          ? const Value.absent()
          : Value(teamId),
      teamName: teamName == null && nullToAbsent
          ? const Value.absent()
          : Value(teamName),
      teamColor: teamColor == null && nullToAbsent
          ? const Value.absent()
          : Value(teamColor),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      projectName: projectName == null && nullToAbsent
          ? const Value.absent()
          : Value(projectName),
      status: Value(status),
      statusType: Value(statusType),
      priority: Value(priority),
      url: Value(url),
      assigneeId: assigneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeId),
      assigneeName: assigneeName == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeName),
      isDeleted: Value(isDeleted),
      isAssigned: Value(isAssigned),
      lastSynced: Value(lastSynced),
    );
  }

  factory CachedIssue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedIssue(
      issueId: serializer.fromJson<String>(json['issueId']),
      identifier: serializer.fromJson<String>(json['identifier']),
      title: serializer.fromJson<String>(json['title']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      teamName: serializer.fromJson<String?>(json['teamName']),
      teamColor: serializer.fromJson<String?>(json['teamColor']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      projectName: serializer.fromJson<String?>(json['projectName']),
      status: serializer.fromJson<String>(json['status']),
      statusType: serializer.fromJson<String>(json['statusType']),
      priority: serializer.fromJson<int>(json['priority']),
      url: serializer.fromJson<String>(json['url']),
      assigneeId: serializer.fromJson<String?>(json['assigneeId']),
      assigneeName: serializer.fromJson<String?>(json['assigneeName']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      isAssigned: serializer.fromJson<bool>(json['isAssigned']),
      lastSynced: serializer.fromJson<DateTime>(json['lastSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'issueId': serializer.toJson<String>(issueId),
      'identifier': serializer.toJson<String>(identifier),
      'title': serializer.toJson<String>(title),
      'teamId': serializer.toJson<String?>(teamId),
      'teamName': serializer.toJson<String?>(teamName),
      'teamColor': serializer.toJson<String?>(teamColor),
      'projectId': serializer.toJson<String?>(projectId),
      'projectName': serializer.toJson<String?>(projectName),
      'status': serializer.toJson<String>(status),
      'statusType': serializer.toJson<String>(statusType),
      'priority': serializer.toJson<int>(priority),
      'url': serializer.toJson<String>(url),
      'assigneeId': serializer.toJson<String?>(assigneeId),
      'assigneeName': serializer.toJson<String?>(assigneeName),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'isAssigned': serializer.toJson<bool>(isAssigned),
      'lastSynced': serializer.toJson<DateTime>(lastSynced),
    };
  }

  CachedIssue copyWith({
    String? issueId,
    String? identifier,
    String? title,
    Value<String?> teamId = const Value.absent(),
    Value<String?> teamName = const Value.absent(),
    Value<String?> teamColor = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    Value<String?> projectName = const Value.absent(),
    String? status,
    String? statusType,
    int? priority,
    String? url,
    Value<String?> assigneeId = const Value.absent(),
    Value<String?> assigneeName = const Value.absent(),
    bool? isDeleted,
    bool? isAssigned,
    DateTime? lastSynced,
  }) => CachedIssue(
    issueId: issueId ?? this.issueId,
    identifier: identifier ?? this.identifier,
    title: title ?? this.title,
    teamId: teamId.present ? teamId.value : this.teamId,
    teamName: teamName.present ? teamName.value : this.teamName,
    teamColor: teamColor.present ? teamColor.value : this.teamColor,
    projectId: projectId.present ? projectId.value : this.projectId,
    projectName: projectName.present ? projectName.value : this.projectName,
    status: status ?? this.status,
    statusType: statusType ?? this.statusType,
    priority: priority ?? this.priority,
    url: url ?? this.url,
    assigneeId: assigneeId.present ? assigneeId.value : this.assigneeId,
    assigneeName: assigneeName.present ? assigneeName.value : this.assigneeName,
    isDeleted: isDeleted ?? this.isDeleted,
    isAssigned: isAssigned ?? this.isAssigned,
    lastSynced: lastSynced ?? this.lastSynced,
  );
  CachedIssue copyWithCompanion(CachedIssuesCompanion data) {
    return CachedIssue(
      issueId: data.issueId.present ? data.issueId.value : this.issueId,
      identifier: data.identifier.present
          ? data.identifier.value
          : this.identifier,
      title: data.title.present ? data.title.value : this.title,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      teamColor: data.teamColor.present ? data.teamColor.value : this.teamColor,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectName: data.projectName.present
          ? data.projectName.value
          : this.projectName,
      status: data.status.present ? data.status.value : this.status,
      statusType: data.statusType.present
          ? data.statusType.value
          : this.statusType,
      priority: data.priority.present ? data.priority.value : this.priority,
      url: data.url.present ? data.url.value : this.url,
      assigneeId: data.assigneeId.present
          ? data.assigneeId.value
          : this.assigneeId,
      assigneeName: data.assigneeName.present
          ? data.assigneeName.value
          : this.assigneeName,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      isAssigned: data.isAssigned.present
          ? data.isAssigned.value
          : this.isAssigned,
      lastSynced: data.lastSynced.present
          ? data.lastSynced.value
          : this.lastSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedIssue(')
          ..write('issueId: $issueId, ')
          ..write('identifier: $identifier, ')
          ..write('title: $title, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamColor: $teamColor, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('status: $status, ')
          ..write('statusType: $statusType, ')
          ..write('priority: $priority, ')
          ..write('url: $url, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isAssigned: $isAssigned, ')
          ..write('lastSynced: $lastSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    issueId,
    identifier,
    title,
    teamId,
    teamName,
    teamColor,
    projectId,
    projectName,
    status,
    statusType,
    priority,
    url,
    assigneeId,
    assigneeName,
    isDeleted,
    isAssigned,
    lastSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedIssue &&
          other.issueId == this.issueId &&
          other.identifier == this.identifier &&
          other.title == this.title &&
          other.teamId == this.teamId &&
          other.teamName == this.teamName &&
          other.teamColor == this.teamColor &&
          other.projectId == this.projectId &&
          other.projectName == this.projectName &&
          other.status == this.status &&
          other.statusType == this.statusType &&
          other.priority == this.priority &&
          other.url == this.url &&
          other.assigneeId == this.assigneeId &&
          other.assigneeName == this.assigneeName &&
          other.isDeleted == this.isDeleted &&
          other.isAssigned == this.isAssigned &&
          other.lastSynced == this.lastSynced);
}

class CachedIssuesCompanion extends UpdateCompanion<CachedIssue> {
  final Value<String> issueId;
  final Value<String> identifier;
  final Value<String> title;
  final Value<String?> teamId;
  final Value<String?> teamName;
  final Value<String?> teamColor;
  final Value<String?> projectId;
  final Value<String?> projectName;
  final Value<String> status;
  final Value<String> statusType;
  final Value<int> priority;
  final Value<String> url;
  final Value<String?> assigneeId;
  final Value<String?> assigneeName;
  final Value<bool> isDeleted;
  final Value<bool> isAssigned;
  final Value<DateTime> lastSynced;
  final Value<int> rowid;
  const CachedIssuesCompanion({
    this.issueId = const Value.absent(),
    this.identifier = const Value.absent(),
    this.title = const Value.absent(),
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    this.status = const Value.absent(),
    this.statusType = const Value.absent(),
    this.priority = const Value.absent(),
    this.url = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.assigneeName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isAssigned = const Value.absent(),
    this.lastSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedIssuesCompanion.insert({
    required String issueId,
    required String identifier,
    required String title,
    this.teamId = const Value.absent(),
    this.teamName = const Value.absent(),
    this.teamColor = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectName = const Value.absent(),
    required String status,
    required String statusType,
    required int priority,
    required String url,
    this.assigneeId = const Value.absent(),
    this.assigneeName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.isAssigned = const Value.absent(),
    required DateTime lastSynced,
    this.rowid = const Value.absent(),
  }) : issueId = Value(issueId),
       identifier = Value(identifier),
       title = Value(title),
       status = Value(status),
       statusType = Value(statusType),
       priority = Value(priority),
       url = Value(url),
       lastSynced = Value(lastSynced);
  static Insertable<CachedIssue> custom({
    Expression<String>? issueId,
    Expression<String>? identifier,
    Expression<String>? title,
    Expression<String>? teamId,
    Expression<String>? teamName,
    Expression<String>? teamColor,
    Expression<String>? projectId,
    Expression<String>? projectName,
    Expression<String>? status,
    Expression<String>? statusType,
    Expression<int>? priority,
    Expression<String>? url,
    Expression<String>? assigneeId,
    Expression<String>? assigneeName,
    Expression<bool>? isDeleted,
    Expression<bool>? isAssigned,
    Expression<DateTime>? lastSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (issueId != null) 'issue_id': issueId,
      if (identifier != null) 'identifier': identifier,
      if (title != null) 'title': title,
      if (teamId != null) 'team_id': teamId,
      if (teamName != null) 'team_name': teamName,
      if (teamColor != null) 'team_color': teamColor,
      if (projectId != null) 'project_id': projectId,
      if (projectName != null) 'project_name': projectName,
      if (status != null) 'status': status,
      if (statusType != null) 'status_type': statusType,
      if (priority != null) 'priority': priority,
      if (url != null) 'url': url,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (assigneeName != null) 'assignee_name': assigneeName,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (isAssigned != null) 'is_assigned': isAssigned,
      if (lastSynced != null) 'last_synced': lastSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedIssuesCompanion copyWith({
    Value<String>? issueId,
    Value<String>? identifier,
    Value<String>? title,
    Value<String?>? teamId,
    Value<String?>? teamName,
    Value<String?>? teamColor,
    Value<String?>? projectId,
    Value<String?>? projectName,
    Value<String>? status,
    Value<String>? statusType,
    Value<int>? priority,
    Value<String>? url,
    Value<String?>? assigneeId,
    Value<String?>? assigneeName,
    Value<bool>? isDeleted,
    Value<bool>? isAssigned,
    Value<DateTime>? lastSynced,
    Value<int>? rowid,
  }) {
    return CachedIssuesCompanion(
      issueId: issueId ?? this.issueId,
      identifier: identifier ?? this.identifier,
      title: title ?? this.title,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamColor: teamColor ?? this.teamColor,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      status: status ?? this.status,
      statusType: statusType ?? this.statusType,
      priority: priority ?? this.priority,
      url: url ?? this.url,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      isDeleted: isDeleted ?? this.isDeleted,
      isAssigned: isAssigned ?? this.isAssigned,
      lastSynced: lastSynced ?? this.lastSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (issueId.present) {
      map['issue_id'] = Variable<String>(issueId.value);
    }
    if (identifier.present) {
      map['identifier'] = Variable<String>(identifier.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (teamColor.present) {
      map['team_color'] = Variable<String>(teamColor.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectName.present) {
      map['project_name'] = Variable<String>(projectName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (statusType.present) {
      map['status_type'] = Variable<String>(statusType.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (assigneeId.present) {
      map['assignee_id'] = Variable<String>(assigneeId.value);
    }
    if (assigneeName.present) {
      map['assignee_name'] = Variable<String>(assigneeName.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (isAssigned.present) {
      map['is_assigned'] = Variable<bool>(isAssigned.value);
    }
    if (lastSynced.present) {
      map['last_synced'] = Variable<DateTime>(lastSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedIssuesCompanion(')
          ..write('issueId: $issueId, ')
          ..write('identifier: $identifier, ')
          ..write('title: $title, ')
          ..write('teamId: $teamId, ')
          ..write('teamName: $teamName, ')
          ..write('teamColor: $teamColor, ')
          ..write('projectId: $projectId, ')
          ..write('projectName: $projectName, ')
          ..write('status: $status, ')
          ..write('statusType: $statusType, ')
          ..write('priority: $priority, ')
          ..write('url: $url, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('assigneeName: $assigneeName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('isAssigned: $isAssigned, ')
          ..write('lastSynced: $lastSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimeEntriesTable timeEntries = $TimeEntriesTable(this);
  late final $CachedIssuesTable cachedIssues = $CachedIssuesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final TimeEntryDao timeEntryDao = TimeEntryDao(this as AppDatabase);
  late final CachedIssueDao cachedIssueDao = CachedIssueDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    timeEntries,
    cachedIssues,
    settings,
  ];
}

typedef $$TimeEntriesTableCreateCompanionBuilder =
    TimeEntriesCompanion Function({
      Value<int> id,
      required String issueId,
      required String issueIdentifier,
      required String issueTitle,
      Value<String?> teamName,
      Value<String?> projectName,
      Value<String?> teamColor,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<int?> durationSeconds,
      Value<bool> isManual,
    });
typedef $$TimeEntriesTableUpdateCompanionBuilder =
    TimeEntriesCompanion Function({
      Value<int> id,
      Value<String> issueId,
      Value<String> issueIdentifier,
      Value<String> issueTitle,
      Value<String?> teamName,
      Value<String?> projectName,
      Value<String?> teamColor,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<int?> durationSeconds,
      Value<bool> isManual,
    });

class $$TimeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueIdentifier => $composableBuilder(
    column: $table.issueIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issueTitle => $composableBuilder(
    column: $table.issueTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamColor => $composableBuilder(
    column: $table.teamColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueIdentifier => $composableBuilder(
    column: $table.issueIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issueTitle => $composableBuilder(
    column: $table.issueTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamColor => $composableBuilder(
    column: $table.teamColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isManual => $composableBuilder(
    column: $table.isManual,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeEntriesTable> {
  $$TimeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issueId =>
      $composableBuilder(column: $table.issueId, builder: (column) => column);

  GeneratedColumn<String> get issueIdentifier => $composableBuilder(
    column: $table.issueIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issueTitle => $composableBuilder(
    column: $table.issueTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamName =>
      $composableBuilder(column: $table.teamName, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamColor =>
      $composableBuilder(column: $table.teamColor, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isManual =>
      $composableBuilder(column: $table.isManual, builder: (column) => column);
}

class $$TimeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeEntriesTable,
          TimeEntry,
          $$TimeEntriesTableFilterComposer,
          $$TimeEntriesTableOrderingComposer,
          $$TimeEntriesTableAnnotationComposer,
          $$TimeEntriesTableCreateCompanionBuilder,
          $$TimeEntriesTableUpdateCompanionBuilder,
          (
            TimeEntry,
            BaseReferences<_$AppDatabase, $TimeEntriesTable, TimeEntry>,
          ),
          TimeEntry,
          PrefetchHooks Function()
        > {
  $$TimeEntriesTableTableManager(_$AppDatabase db, $TimeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> issueId = const Value.absent(),
                Value<String> issueIdentifier = const Value.absent(),
                Value<String> issueTitle = const Value.absent(),
                Value<String?> teamName = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String?> teamColor = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
              }) => TimeEntriesCompanion(
                id: id,
                issueId: issueId,
                issueIdentifier: issueIdentifier,
                issueTitle: issueTitle,
                teamName: teamName,
                projectName: projectName,
                teamColor: teamColor,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: durationSeconds,
                isManual: isManual,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String issueId,
                required String issueIdentifier,
                required String issueTitle,
                Value<String?> teamName = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String?> teamColor = const Value.absent(),
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> isManual = const Value.absent(),
              }) => TimeEntriesCompanion.insert(
                id: id,
                issueId: issueId,
                issueIdentifier: issueIdentifier,
                issueTitle: issueTitle,
                teamName: teamName,
                projectName: projectName,
                teamColor: teamColor,
                startTime: startTime,
                endTime: endTime,
                durationSeconds: durationSeconds,
                isManual: isManual,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeEntriesTable,
      TimeEntry,
      $$TimeEntriesTableFilterComposer,
      $$TimeEntriesTableOrderingComposer,
      $$TimeEntriesTableAnnotationComposer,
      $$TimeEntriesTableCreateCompanionBuilder,
      $$TimeEntriesTableUpdateCompanionBuilder,
      (TimeEntry, BaseReferences<_$AppDatabase, $TimeEntriesTable, TimeEntry>),
      TimeEntry,
      PrefetchHooks Function()
    >;
typedef $$CachedIssuesTableCreateCompanionBuilder =
    CachedIssuesCompanion Function({
      required String issueId,
      required String identifier,
      required String title,
      Value<String?> teamId,
      Value<String?> teamName,
      Value<String?> teamColor,
      Value<String?> projectId,
      Value<String?> projectName,
      required String status,
      required String statusType,
      required int priority,
      required String url,
      Value<String?> assigneeId,
      Value<String?> assigneeName,
      Value<bool> isDeleted,
      Value<bool> isAssigned,
      required DateTime lastSynced,
      Value<int> rowid,
    });
typedef $$CachedIssuesTableUpdateCompanionBuilder =
    CachedIssuesCompanion Function({
      Value<String> issueId,
      Value<String> identifier,
      Value<String> title,
      Value<String?> teamId,
      Value<String?> teamName,
      Value<String?> teamColor,
      Value<String?> projectId,
      Value<String?> projectName,
      Value<String> status,
      Value<String> statusType,
      Value<int> priority,
      Value<String> url,
      Value<String?> assigneeId,
      Value<String?> assigneeName,
      Value<bool> isDeleted,
      Value<bool> isAssigned,
      Value<DateTime> lastSynced,
      Value<int> rowid,
    });

class $$CachedIssuesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identifier => $composableBuilder(
    column: $table.identifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamColor => $composableBuilder(
    column: $table.teamColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusType => $composableBuilder(
    column: $table.statusType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAssigned => $composableBuilder(
    column: $table.isAssigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedIssuesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get issueId => $composableBuilder(
    column: $table.issueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identifier => $composableBuilder(
    column: $table.identifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamName => $composableBuilder(
    column: $table.teamName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamColor => $composableBuilder(
    column: $table.teamColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusType => $composableBuilder(
    column: $table.statusType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAssigned => $composableBuilder(
    column: $table.isAssigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedIssuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedIssuesTable> {
  $$CachedIssuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get issueId =>
      $composableBuilder(column: $table.issueId, builder: (column) => column);

  GeneratedColumn<String> get identifier => $composableBuilder(
    column: $table.identifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get teamName =>
      $composableBuilder(column: $table.teamName, builder: (column) => column);

  GeneratedColumn<String> get teamColor =>
      $composableBuilder(column: $table.teamColor, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectName => $composableBuilder(
    column: $table.projectName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get statusType => $composableBuilder(
    column: $table.statusType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get assigneeId => $composableBuilder(
    column: $table.assigneeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assigneeName => $composableBuilder(
    column: $table.assigneeName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get isAssigned => $composableBuilder(
    column: $table.isAssigned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => column,
  );
}

class $$CachedIssuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedIssuesTable,
          CachedIssue,
          $$CachedIssuesTableFilterComposer,
          $$CachedIssuesTableOrderingComposer,
          $$CachedIssuesTableAnnotationComposer,
          $$CachedIssuesTableCreateCompanionBuilder,
          $$CachedIssuesTableUpdateCompanionBuilder,
          (
            CachedIssue,
            BaseReferences<_$AppDatabase, $CachedIssuesTable, CachedIssue>,
          ),
          CachedIssue,
          PrefetchHooks Function()
        > {
  $$CachedIssuesTableTableManager(_$AppDatabase db, $CachedIssuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedIssuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedIssuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedIssuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> issueId = const Value.absent(),
                Value<String> identifier = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> teamId = const Value.absent(),
                Value<String?> teamName = const Value.absent(),
                Value<String?> teamColor = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> statusType = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> assigneeName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isAssigned = const Value.absent(),
                Value<DateTime> lastSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedIssuesCompanion(
                issueId: issueId,
                identifier: identifier,
                title: title,
                teamId: teamId,
                teamName: teamName,
                teamColor: teamColor,
                projectId: projectId,
                projectName: projectName,
                status: status,
                statusType: statusType,
                priority: priority,
                url: url,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                isDeleted: isDeleted,
                isAssigned: isAssigned,
                lastSynced: lastSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String issueId,
                required String identifier,
                required String title,
                Value<String?> teamId = const Value.absent(),
                Value<String?> teamName = const Value.absent(),
                Value<String?> teamColor = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> projectName = const Value.absent(),
                required String status,
                required String statusType,
                required int priority,
                required String url,
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> assigneeName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> isAssigned = const Value.absent(),
                required DateTime lastSynced,
                Value<int> rowid = const Value.absent(),
              }) => CachedIssuesCompanion.insert(
                issueId: issueId,
                identifier: identifier,
                title: title,
                teamId: teamId,
                teamName: teamName,
                teamColor: teamColor,
                projectId: projectId,
                projectName: projectName,
                status: status,
                statusType: statusType,
                priority: priority,
                url: url,
                assigneeId: assigneeId,
                assigneeName: assigneeName,
                isDeleted: isDeleted,
                isAssigned: isAssigned,
                lastSynced: lastSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedIssuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedIssuesTable,
      CachedIssue,
      $$CachedIssuesTableFilterComposer,
      $$CachedIssuesTableOrderingComposer,
      $$CachedIssuesTableAnnotationComposer,
      $$CachedIssuesTableCreateCompanionBuilder,
      $$CachedIssuesTableUpdateCompanionBuilder,
      (
        CachedIssue,
        BaseReferences<_$AppDatabase, $CachedIssuesTable, CachedIssue>,
      ),
      CachedIssue,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimeEntriesTableTableManager get timeEntries =>
      $$TimeEntriesTableTableManager(_db, _db.timeEntries);
  $$CachedIssuesTableTableManager get cachedIssues =>
      $$CachedIssuesTableTableManager(_db, _db.cachedIssues);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
