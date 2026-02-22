class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session
  include GraphqlDevise::SetUserByToken

  def execute
    if defined?(Bullet)
      Bullet.enable = false
    end

    timer = ExecutionTimer.new(execution_name: "GraphQL Controller")
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    timer.log_elapsed_time(phase_name: "after preparing variables")

    ctx = nil
    if Rails.env.development?
      StackProf.run(mode: :wall, out: "tmp/stackprof-ctx.dump", interval: 1000) do
        ctx = build_context
      end
    else
      ctx = build_context
    end
    context = ctx

    timer.log_elapsed_time(phase_name: "after building context")

    result = nil
    if Rails.env.development?
      StackProf.run(mode: :cpu, out: "tmp/stackprof-gql.dump", interval: 1000) do
        result = BackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
      end
    else
      result = BackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    end

    timer.log_elapsed_time(phase_name: "after schema.execute")

    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  ensure
    if defined?(Bullet)
      Bullet.enable = true
    end
  end

  private

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def build_context
    context_for_devise = gql_devise_context(LoginUser)
    login_user = context_for_devise[:current_resource]
    return context_for_devise if login_user.blank?

    context_for_devise.merge(
      {
        current_user_id: login_user.user.id
      })
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [{ message: e.message, backtrace: e.backtrace }], data: {} }, status: 500
  end
end
