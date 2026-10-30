module AdminAuthenticationSpecSupport
  def stub_admin_credentials
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_USERNAME").and_return("test-admin")
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return("test-only-admin-password")
  end

  def admin_headers
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("test-admin", "test-only-admin-password") }
  end
end

module AuthenticatedAdminRequests
  include AdminAuthenticationSpecSupport

  [:get, :post, :patch, :put, :delete].each do |verb|
    define_method(verb) do |path, **options|
      super(path, **options.merge(headers: admin_headers.merge(options[:headers] || {})))
    end
  end

  def follow_redirect!(**options)
    super(**options.merge(headers: admin_headers.merge(options[:headers] || {})))
  end
end
