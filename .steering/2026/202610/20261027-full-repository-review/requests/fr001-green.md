kind: test-runner
request_id: fr001-green
attempt: 1
tasklist: /workspace/nanitabe/.steering/2026/202610/20261027-full-repository-review/tasklist.md
task: FR-001 管理CRUDの認証
status: requested
checks: 管理認証の拒否条件と、認証済みの既存CRUD/画面操作が成功すること
DoD: 全指定specが成功し、未認証/誤認証/未設定は401、認証済みCRUDは従来契約を満たす
command: docker exec -e RAILS_ENV=test nanitabe-review-tests-backend-1 bundle exec rspec spec/requests/admin spec/system/admin/food/dish/word/normalize_words_spec.rb
artifact_directory: /workspace/nanitabe/.steering/2026/202610/20261027-full-repository-review/requests/
allowed_context: request、対象spec、backend/app/controllers/admin、backend/spec/support/admin_authentication.rb、testing方針。RAILS_ENV=testのみ。実装とtasklistは変更しない。
