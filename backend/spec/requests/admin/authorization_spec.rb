require "rails_helper"

RSpec.describe "管理CRUDの認証", type: :request do
  let(:credentials) { ActionController::HttpAuthentication::Basic.encode_credentials("review-admin", "test-only-admin-password") }
  let!(:effort) { DishEffortLevel.create!(meal_position: 1, minutes: 10, label: "既存") }
  let!(:word) { NormalizeWord.create!(entered_source: "test", entered_destination: "test", source: "test", destination: "test") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_USERNAME").and_return("review-admin")
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return("test-only-admin-password")
  end

  def operations
    [
      [:get, "/admin/food/dish/effort_level/dish_effort_levels", {}],
      [:post, "/admin/food/dish/effort_level/dish_effort_levels", { dish_effort_level: { meal_position: 2, minutes: 15, label: "追加" } }],
      [:patch, "/admin/food/dish/effort_level/dish_effort_levels/#{effort.id}", { dish_effort_level: { label: "変更" } }],
      [:delete, "/admin/food/dish/effort_level/dish_effort_levels/#{effort.id}", {}],
      [:get, "/admin/food/dish/word/normalize_words", {}],
      [:post, "/admin/food/dish/word/normalize_words", { normalize_word: { source: "new", destination: "new" } }],
      [:patch, "/admin/food/dish/word/normalize_words/#{word.id}", { normalize_word: { source: "changed", destination: "changed" } }],
      [:delete, "/admin/food/dish/word/normalize_words/#{word.id}", {}],
    ]
  end

  it "未認証のすべてのCRUDを拒否しDBを変更しない" do
    original = [DishEffortLevel.all.map(&:attributes), NormalizeWord.all.map(&:attributes)]
    operations.each do |verb, path, params|
      public_send(verb, path, params:)
      expect(response).to have_http_status(:unauthorized)
    end
    expect([DishEffortLevel.all.map(&:attributes), NormalizeWord.all.map(&:attributes)]).to eq(original)
  end

  it "誤った管理用認証を拒否する" do
    get operations.first[1], headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("review-admin", "wrong") }
    expect(response).to have_http_status(:unauthorized)
  end

  it "パスワードを欠くBasic認証も拒否する" do
    get operations.first[1], headers: { "Authorization" => "Basic #{Base64.strict_encode64('review-admin')}" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "管理用認証を持つ利用者だけが両管理画面を開ける" do
    operations.select { |verb, _, _| verb == :get }.each do |_, path, _|
      get path, headers: { "Authorization" => credentials }
      expect(response).to have_http_status(:ok)
    end
  end

  it "管理用認証が未設定なら空文字の認証も拒否する" do
    allow(ENV).to receive(:[]).with("ADMIN_USERNAME").and_return(nil)
    allow(ENV).to receive(:[]).with("ADMIN_PASSWORD").and_return(nil)
    get operations.first[1], headers: { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials("", "") }
    expect(response).to have_http_status(:unauthorized)
  end
end
