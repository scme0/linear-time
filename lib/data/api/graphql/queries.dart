/// GraphQL queries for the Linear API.

/// Common issue fields used across queries.
const String _issueFields = '''
  id
  identifier
  title
  priority
  url
  assignee {
    id
    name
  }
  state {
    name
    type
  }
  team {
    id
    name
    color
  }
  project {
    id
    name
  }
''';

const String viewerQuery = r'''
query Viewer {
  viewer {
    id
    name
    email
  }
}
''';

final String assignedIssuesQuery = '''
query AssignedIssues(\$after: String, \$filter: IssueFilter) {
  viewer {
    assignedIssues(first: 50, after: \$after, filter: \$filter) {
      nodes {
        $_issueFields
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
''';

final String issueByIdQuery = '''
query IssueById(\$id: String!) {
  issue(id: \$id) {
    $_issueFields
  }
}
''';

final String issueByIdentifierQuery = '''
query IssueByIdentifier(\$identifier: String!) {
  issueSearch(query: \$identifier, first: 1) {
    nodes {
      $_issueFields
    }
  }
}
''';

final String teamIssuesQuery = '''
query TeamIssues(\$teamId: String!, \$after: String, \$filter: IssueFilter) {
  team(id: \$teamId) {
    issues(first: 50, after: \$after, filter: \$filter) {
      nodes {
        $_issueFields
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
''';

const String teamsQuery = r'''
query MyTeams {
  viewer {
    teamMemberships {
      nodes {
        team {
          id
          name
          color
        }
      }
    }
  }
}
''';

const String projectsQuery = r'''
query Projects {
  projects {
    nodes {
      id
      name
    }
  }
}
''';
