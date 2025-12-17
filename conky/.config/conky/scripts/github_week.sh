#!/bin/bash
source "$HOME/.config/conky/secrets.env"

FROM=$(date -d '6 days ago' +"%Y-%m-%dT00:00:00Z")
TO=$(date -d 'tomorrow' +"%Y-%m-%dT00:00:00Z")

# Build JSON properly without heredoc escaping issues
QUERY=$(
  cat <<EOF
{
  "query": "query { user(login: \"$GITHUB_USER\") { contributionsCollection(from: \"$FROM\", to: \"$TO\") { contributionCalendar { totalContributions } } } }"
}
EOF
)

curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$QUERY" \
  https://api.github.com/graphql |
  jq -r '.data.user.contributionsCollection.contributionCalendar.totalContributions // 0'
