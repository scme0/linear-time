/// GraphQL queries for the Linear API.

const String viewerQuery = r'''
query Viewer {
  viewer {
    id
    name
    email
  }
}
''';

const String assignedIssuesQuery = r'''
query AssignedIssues($after: String, $filter: IssueFilter) {
  viewer {
    assignedIssues(first: 50, after: $after, filter: $filter) {
      nodes {
        id
        identifier
        title
        priority
        url
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
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
''';

const String issueByIdQuery = r'''
query IssueById($id: String!) {
  issue(id: $id) {
    id
    identifier
    title
    priority
    url
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
  }
}
''';

const String issueByIdentifierQuery = r'''
query IssueByIdentifier($identifier: String!) {
  issueSearch(query: $identifier, first: 1) {
    nodes {
      id
      identifier
      title
      priority
      url
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
    }
  }
}
''';

const String teamIssuesQuery = r'''
query TeamIssues($teamId: String!, $after: String, $filter: IssueFilter) {
  team(id: $teamId) {
    issues(first: 50, after: $after, filter: $filter) {
      nodes {
        id
        identifier
        title
        priority
        url
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
query Teams {
  teams {
    nodes {
      id
      name
      color
    }
  }
}
''';

const String projectsQuery = r'''
query Projects($teamId: String) {
  projects(filter: { accessibleTeams: { id: { eq: $teamId } } }) {
    nodes {
      id
      name
    }
  }
}
''';
