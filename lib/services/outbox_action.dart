import 'dart:convert';

import 'package:equatable/equatable.dart';

class OutboxAction extends Equatable {
  final String id;
  final String kind;
  final String table;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic>? values;
  final Map<String, dynamic>? match;
  final DateTime createdAt;

  const OutboxAction({
    required this.id,
    required this.kind,
    required this.table,
    required this.rows,
    this.values,
    this.match,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'table': table,
      'rows': rows,
      if (values != null) 'values': values,
      if (match != null) 'match': match,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory OutboxAction.fromJson(Map<String, dynamic> json) {
    return OutboxAction(
      id: json['id'] as String,
      kind: (json['kind'] as String?) ?? 'insert',
      table: json['table'] as String,
      rows: ((json['rows'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      values: json['values'] is Map
          ? (json['values'] as Map).cast<String, dynamic>()
          : null,
      match: json['match'] is Map
          ? (json['match'] as Map).cast<String, dynamic>()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now().toUtc(),
    );
  }

  static List<OutboxAction> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <OutboxAction>[];
    return decoded
        .whereType<Map>()
        .map((e) => OutboxAction.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  static String encodeList(List<OutboxAction> actions) {
    return jsonEncode(actions.map((a) => a.toJson()).toList());
  }

  String fingerprint() => _stableEncode(toJson());

  String businessFingerprint() => _stableEncode({
        'kind': kind,
        'table': table,
        'rows': rows,
        if (values != null) 'values': values,
        if (match != null) 'match': match,
      });

  static String _stableEncode(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '"$key":${_stableEncode(value[key])}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_stableEncode).join(',')}]';
    }
    return jsonEncode(value);
  }

  @override
  List<Object?> get props => [id, kind, table, rows, values, match, createdAt];
}
