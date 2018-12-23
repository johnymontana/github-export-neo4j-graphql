import { ApolloServer, gql } from "apollo-server";
import { makeAugmentedSchema } from "neo4j-graphql-js";

// Construct a schema, using GraphQL schema language
const typeDefs = gql`
  type Query {
    hello: String
  }

  type Launch {
    id: ID
    name: String
    missionPatch: String
  }
`;

// Provide resolver functions for your schema fields
const resolvers = {
  Query: {
    hello: (root, args, context) => "Hello world!"
  }
};

const server = new ApolloServer({
  typeDefs,
  resolvers
});

server.listen().then(({ url }) => {
  console.log(`🚀 Server ready at ${url}`);
});
