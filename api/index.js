import { ApolloServer, gql } from "apollo-server";
import { makeAugmentedSchema } from "neo4j-graphql-js";
import { v1 as neo4j } from "neo4j-driver";

// Construct a schema, using GraphQL schema language
const typeDefs = `
  type Repository {
    url: ID!
    created_at: DateTime
    description: String
    name: String
    website: String
    webhooks: [Webhook] @relation(name: "HAS_WEBHOOK", direction: "OUT")
    pull_requests: [PullRequest] @relation(name: "BASE", direction: "IN")
    pr_count: Int @cypher(statement: "RETURN SIZE((this)<-[:BASE]-())")
  }

  type PullRequest {
    url: ID!
    title: String
    created_at: DateTime
    body: String
    head: [Repository] @relation(name: "HEAD", direction: "IN")
    base: [Repository] @relation(name: "BASE", direction: "IN")
    user: User @relation(name: "OPENS", direction: "IN")
  }

  type User {
    url: ID!
    created_at: DateTime
    company: String
    location: String
    name: String
    login: String
    bio: String
    repositories: [Repository] @relation(name: "OWNS", direction: "OUT")
    pull_requests: [PullRequest] @relation(name: "OPENS", direction: "OUT")
  }

  type Webhook {
    url: ID!
  }
`;

const schema = makeAugmentedSchema({
  typeDefs
});

const driver = neo4j.driver(
  process.env.NEO4J_URI || "bolt://localhost:7687",
  neo4j.auth.basic(
    process.env.NEO4J_USER || "neo4j",
    process.env.NEO4J_PASSWORD || "neo4j"
  )
);

const server = new ApolloServer({
  schema,
  context: { driver }
});

server.listen().then(({ url }) => {
  console.log(`🚀 Server ready at ${url}`);
});
