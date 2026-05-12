import 'package:graphql/client.dart';

import 'graphql/queries.dart';

class LinearApiClient {
  LinearApiClient({required String apiKey})
      : _client = GraphQLClient(
          link: AuthLink(getToken: () => apiKey).concat(
            HttpLink('https://api.linear.app/graphql'),
          ),
          cache: GraphQLCache(),
        );

  final GraphQLClient _client;

  /// Validate the API key by fetching the current user.
  Future<Map<String, dynamic>?> fetchViewer() async {
    final result = await _client.query(
      QueryOptions(document: gql(viewerQuery)),
    );
    if (result.hasException) return null;
    return result.data?['viewer'] as Map<String, dynamic>?;
  }

  /// Fetch issues assigned to the current user.
  /// Optionally filter by status types to exclude completed/cancelled.
  Future<List<Map<String, dynamic>>> fetchAssignedIssues({
    List<String>? excludeStatusTypes,
    String? after,
  }) async {
    final allIssues = <Map<String, dynamic>>[];
    String? cursor = after;

    do {
      Map<String, dynamic>? filter;
      if (excludeStatusTypes != null && excludeStatusTypes.isNotEmpty) {
        filter = {
          'state': {
            'type': {
              'nin': excludeStatusTypes,
            }
          }
        };
      }

      final result = await _client.query(
        QueryOptions(
          document: gql(assignedIssuesQuery),
          variables: {
            if (cursor != null) 'after': cursor,
            if (filter != null) 'filter': filter,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) break;

      final data = result.data?['viewer']?['assignedIssues'];
      if (data == null) break;

      final nodes = (data['nodes'] as List).cast<Map<String, dynamic>>();
      allIssues.addAll(nodes);

      final pageInfo = data['pageInfo'] as Map<String, dynamic>;
      if (pageInfo['hasNextPage'] == true) {
        cursor = pageInfo['endCursor'] as String?;
      } else {
        break;
      }
    } while (true);

    return allIssues;
  }

  /// Fetch a single issue by its UUID.
  Future<Map<String, dynamic>?> fetchIssueById(String id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(issueByIdQuery),
        variables: {'id': id},
      ),
    );
    if (result.hasException) return null;
    return result.data?['issue'] as Map<String, dynamic>?;
  }

  /// Search for an issue by identifier (e.g. "ENG-123") or text.
  Future<Map<String, dynamic>?> fetchIssueByIdentifier(
      String identifier) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(issueByIdentifierQuery),
        variables: {'identifier': identifier},
      ),
    );
    if (result.hasException) return null;
    final nodes = result.data?['issueSearch']?['nodes'] as List?;
    if (nodes == null || nodes.isEmpty) return null;
    return nodes.first as Map<String, dynamic>;
  }

  /// Fetch issues for a specific team.
  Future<List<Map<String, dynamic>>> fetchTeamIssues({
    required String teamId,
    List<String>? excludeStatusTypes,
  }) async {
    final allIssues = <Map<String, dynamic>>[];
    String? cursor;

    do {
      Map<String, dynamic>? filter;
      if (excludeStatusTypes != null && excludeStatusTypes.isNotEmpty) {
        filter = {
          'state': {
            'type': {'nin': excludeStatusTypes}
          }
        };
      }

      final result = await _client.query(
        QueryOptions(
          document: gql(teamIssuesQuery),
          variables: {
            'teamId': teamId,
            if (cursor != null) 'after': cursor,
            if (filter != null) 'filter': filter,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) break;

      final data = result.data?['team']?['issues'];
      if (data == null) break;

      final nodes = (data['nodes'] as List).cast<Map<String, dynamic>>();
      allIssues.addAll(nodes);

      final pageInfo = data['pageInfo'] as Map<String, dynamic>;
      if (pageInfo['hasNextPage'] == true) {
        cursor = pageInfo['endCursor'] as String?;
      } else {
        break;
      }
    } while (true);

    return allIssues;
  }

  /// Fetch teams the current user is a member of.
  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final result = await _client.query(
      QueryOptions(document: gql(teamsQuery)),
    );
    if (result.hasException) return [];
    final memberships =
        result.data?['viewer']?['teamMemberships']?['nodes'] as List?;
    if (memberships == null) return [];
    return memberships
        .map((m) => m['team'] as Map<String, dynamic>)
        .toList();
  }

  /// Fetch all projects accessible to the user.
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final result = await _client.query(
      QueryOptions(document: gql(projectsQuery)),
    );
    if (result.hasException) return [];
    final nodes = result.data?['projects']?['nodes'] as List?;
    return nodes?.cast<Map<String, dynamic>>() ?? [];
  }
}
