# github_oidc

GitHub Actions が Terraform を実行するための AWS role を作る module。`envs/prod` から呼ぶ。

## 持つもの

- plan role `<name_prefix>-terraform-plan`: `ReadOnlyAccess` と、state 用 S3 bucket・lock 用 DynamoDB table の読み書き。
- apply role `<name_prefix>-terraform-apply-prod`、`<name_prefix>-terraform-apply-review`: `AdministratorAccess`。

## 持たないもの

GitHub の OIDC identity provider（`token.actions.githubusercontent.com`）。provider は account に一つしか作れず、同じ account の別 repository（x_favorites）の Terraform が所有している。この module は `data "aws_iam_openid_connect_provider"` で参照するだけである。

依存: x_favorites の Terraform が provider を削除すると、この module の plan が失敗する。削除する側は先にこの依存を確認すること。

## role の信頼条件

いずれも audience は `sts.amazonaws.com`。

| role | `sub` |
| --- | --- |
| plan | `repo:<repository>:pull_request`、`repo:<repository>:ref:refs/heads/*`（PR と手動起動） |
| apply（prod） | `repo:<repository>:environment:prod` だけ |
| apply（review） | `repo:<repository>:environment:review` だけ |

prod の apply は GitHub Environment `prod` の deployment branch 制限（`main` だけ）と合わせて `main` に限られる。
