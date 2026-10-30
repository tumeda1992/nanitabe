require_relative "./graphql_helper"

def fetch_auth_header_values(existing_user_id: nil)
  existing_login_user = LoginUser.where(uid: auth_variables(existing_user_id)[:email]).joins(:user)
  credential = if existing_login_user.present?
                 fetch_exisiting_login_user_credential(existing_user_id)
               else
                 fetch_new_login_user_credential(existing_user_id)
               end

  {
    "access-token" => credential["accessToken"],
    "client" => credential["client"],
    "uid" => credential["uid"],
  }
end

def fetch_mutation_with_auth(mutation_string, variables, existing_user_id = nil)
  headers = fetch_auth_header_values(existing_user_id:)
  fetch_mutation(mutation_string, variables, headers:)
end

def fetch_exisiting_login_user_credential(existing_user_id)
  login_mutation = <<~GRAPHQL
    mutation login($email: String!, $password: String!) {
      loginUserLogin(email: $email, password: $password) {
        credentials {
          accessToken
          client
          uid
        }
      }
    }
  GRAPHQL
  variables = auth_variables(existing_user_id)
  fetch_mutation(login_mutation, variables)["loginUserLogin"]["credentials"]
end

def fetch_new_login_user_credential(existing_user_id)
  signup_mutation = <<~GRAPHQL
    mutation signup(
        $email: String = "",
        $password: String = "",
        $userid: Int,
      ) {
      loginUserRegister(
        email: $email,
        password: $password,
        passwordConfirmation: $password
        userid: $userid
      ) {
        credentials {
          accessToken
          client
          uid
        }
      }
    }
  GRAPHQL
  variables = auth_variables(existing_user_id).merge(userid: existing_user_id)
  fetch_mutation(signup_mutation, variables)["loginUserRegister"]["credentials"]
end

def auth_variables(existing_user_id = nil)
  {
    email: existing_user_id ? "test_user_#{existing_user_id}@example.com" : "default_test_user@example.com",
    password: "default_test_user",
  }
end
