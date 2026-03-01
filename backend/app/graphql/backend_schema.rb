class BackendSchema < GraphQL::Schema
  # 後述の `query(Types::QueryType)` とかの定義と重複すると言われるが、重複して書くのがGraphqlDevise推奨の書き方。
  use GraphqlDevise::SchemaPlugin.new(
    query:            Types::QueryType,
    mutation:         Types::MutationType,
    resource_loaders: [
      GraphqlDevise::ResourceLoader.new(
        LoginUser,
        # skip: [:resister]
        operations: {
          # LoginUserだけでなく、Userも作るラッパー。以下のレスポンスをsuperで呼び出して生成
          # https://github.com/graphql-devise/graphql_devise/blob/master/lib/graphql_devise/mutations/register.rb
          register: Rails.env.test? ? Mutations::Auth::SignUpForTest : Mutations::Auth::SignUp,
        }
      )
    ],
  )
  mutation(Types::MutationType)
  query(Types::QueryType)

  # For batch-loading (see https://graphql-ruby.org/dataloader/overview.html)
  use GraphQL::Dataloader

  # GraphQL-Ruby calls this when something goes wrong while running a query:
  def self.type_error(err, context)
    # if err.is_a?(GraphQL::InvalidNullError)
    #   # report to your bug tracker here
    #   return nil
    # end
    super
  end

  # Union and Interface Resolution
  def self.resolve_type(abstract_type, obj, ctx)
    # TODO: Implement this method
    # to return the correct GraphQL object type for `obj`
    raise(GraphQL::RequiredImplementationMissingError)
  end

  # Stop validating when it encounters this many errors:
  validate_max_errors(100)

  # Relay-style Object Identification:

  # Return a string UUID for `object`
  def self.id_from_object(object, type_definition, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    object.to_gid_param
  end

  # Given a string UUID, find the object
  def self.object_from_id(global_id, query_ctx)
    # For example, use Rails' GlobalID library (https://github.com/rails/globalid):
    GlobalID.find(global_id)
  end
end
