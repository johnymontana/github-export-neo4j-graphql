CREATE CONSTRAINT ON (r:Repository) ASSERT r.url IS UNIQUE;
CREATE CONSTRAINT ON (u:User) ASSERT u.url IS UNIQUE;
CREATE CONSTRAINT ON (h:Webhook) ASSERT h.url IS UNIQUE;
CREATE CONSTRAINT ON (p:PullRequest) ASSERT p.url IS UNIQUE;
CREATE CONSTRAINT ON (i:Issue) ASSERT i.url IS UNIQUE;
CREATE CONSTRAINT ON (c:IssueComment) ASSERT c.url IS UNIQUE;

// load repositories
UNWIND ["repositories_000001.json", "repositories_000002.json"] AS file
CALL apoc.load.json($baseURL + file) YIELD value 
// only import public repos
WITH value AS repo WHERE repo.private = false
MERGE (r:Repository {url: repo.url})
SET r += repo {.name, .description, .website, created_at: DateTime(repo.created_at)}

MERGE (u:User {url: repo.owner})
MERGE (r)<-[:OWNS]-(u)

FOREACH (collab IN repo.collaborators | 
    MERGE (c:User {url: collab.user})
    MERGE (c)-[cr:COLLABORATES]->(r)
    SET cr.permission = collab.permission
)

FOREACH (webhook IN repo.webhooks | 
    MERGE (w:Webhook {url: webhook.payload_url})
    MERGE (r)-[:HAS_WEBHOOK]->(w)
);

// load users
CALL apoc.load.json($baseURL + "users_000001.json") YIELD value 
MERGE (u:User {url: value.url})
SET u  += value {created_at: DateTime(value.created_at), .avatar_url, .website, .name, .bio, .company, .location, .login};

// load pull requests
CALL apoc.load.json($baseURL + "pull_requests_000001.json") YIELD value 
MERGE (pr:PullRequest {url: value.url})
SET pr += value{created_at: DateTime(value.created_at), closed_at: DateTime(value.closed_at), merged_at: DateTime(value.merged_at), .title, .body }
MERGE (head:Repository {url: coalesce(value.head.repo,"")})
MERGE (head)<-[h:HEAD]-(pr)
SET h = {sha: value.head.sha, ref: value.head.ref}
MERGE (base:Repository {url: value.base.repo})
MERGE (base)<-[b:BASE]-(pr)
SET b = {sha: value.base.sha, ref: value.base.ref}
MERGE (u:User {url: value.user})
MERGE (u)-[:OPENS]->(pr);

// load issues
CALL apoc.load.json($baseURL + "issues_000001.json") YIELD value 
MERGE (i:Issue {url: value.url})
SET i += value {.title, .body, created_at: DateTime(value.created_at), closed_at: DateTime(value.closed_at)}
MERGE (u:User {url: value.user})
MERGE (u)-[:OPENED]->(i)
MERGE (r:Repository {url: value.repository})
MERGE (i)<-[:HAS_ISSUE]-(r);

// load issue comments
CALL apoc.load.json($baseURL + "issue_comments_000001.json") YIELD value
WITH value WHERE value.issue IS NOT NULL
MERGE (ic:IssueComment {url: value.url})
SET ic += value {.body, created_at: DateTime(value.created_at)}
MERGE (u:User {url: value.user})
MERGE (u)-[:AUTHORED]->(ic)
MERGE (r:Issue {url: value.issue})
MERGE (r)-[:HAS_COMMENT]->(ic);