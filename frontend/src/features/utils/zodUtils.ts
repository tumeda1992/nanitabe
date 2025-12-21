/*
  NOTE:
    react-hook-form経由のzodRezolverで、入力値以外の変数を受け取り管理したい場合、
    「値の変化に合わせてuseEffectでsetValueで値を詰める」のがオススメ。

    フォーム処理としてシンプルに、onChangeで入力に合わせて値を変えていくから、
    変数の変化に合わせてはくれない。

    そのため、stateの値をhiddenで持っても変化に追随してくれなかったり、
    数値を持つと、空の場合にnanになって扱いに苦しんだりする

    その他値を詰める場合のケーススタディ
    - 条件によって値を変えない定数を入れる
      - hiddenで扱って問題ない
      - 空の値が入らずvalueAsNumberでNanにならない前提
    - registerで登録される入力値だが、FormProvider配下の別Form
      - watchで値取得（多分getValuesだと1回しか値取得しない）

    ※定義されているものが0になっても、このコメントを残すためにこのファイルは残す。
    どうせこのファイルに行き着くときは同様の問題関心だろうから。
 */

export const convertFromStringToNumOrNull = (value, context) => {
  const parsed = parseInt(value);
  if (Number.isNaN(parsed)) {
    return null;
  }
  return parsed;
};
