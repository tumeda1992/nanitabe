# Load the Rails application.
require_relative "application"

# Silence "Object types must have fields" warning
GraphqlDevise::Types::QueryType.has_no_fields(true)
GraphqlDevise::Types::MutationType.has_no_fields(true)

# Initialize the Rails application.
Rails.application.initialize!
