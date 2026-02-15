Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  namespace :admin do
    namespace :food do
      namespace :dish do
        namespace :word do
          resources :normalize_words, except: [:show]
        end
      end
    end
  end
end
