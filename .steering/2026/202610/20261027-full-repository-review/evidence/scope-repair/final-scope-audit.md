# 最終範囲照合（source 3d832f5）

基準 `d58c473`、採用元snapshot `608ed3d`、対象source `3d832f5`。保護3fileとsteeringを除く差分124 pathに候補指摘を対応付け、候補なし0、基準後の採用IDでpath欠落0。機械可読結果は[final-scope-map.json](final-scope-map.json)。

この対応表はcommitが触れたpathの候補であり、各hunkの形式的な網羅証明ではない。別途 `608ed3d..f9a6359` 差分を実読し取消・保留・採用に分類、FR-018の4 pathも `3d832f5` で実読した。各指摘のDoDと実測はtasklistおよび個別resultを参照する。全体検証の代替ではない。

FR-018の2 Commandは `25471fd` とbyte一致し、2 specは正常返却・枠保持・rollbackを追加。枠解除は保留。FR-015は2 sourceと2 specに限定。FR-019 unique/migration、FR-023 literal化、FR-028 private構成、CR-003拒否、FR-015追加UIは保留。FR-032 S01–S08、FR-033 I01–I05は `608ed3d` と一致し、先行8件を保持。FR-001 WIPは基準前からあり、`affd7ec` はFR-002であってFR-001の根拠ではない。`.codex/rules/default.rules` はレビュー修正外の既存branch設定として独立分類した。

この照合担当はtest・DB・AWS・ブラウザ・Git変更を行っていない。

## pathと候補指摘

| path | 候補指摘（そのpathに触れたcommit） |
| --- | --- |
| `.codex/rules/default.rules` | independent Codex rules (cbfd10d) |
| `.github/workflows/backend-deploy.yml` | FR-029 (d3e4515, b42acb9) |
| `.github/workflows/ci-frontend-build-verification.yml` | FR-030 (a871b4c, de54d5e) |
| `backend/app/controllers/admin/food/dish/word/normalize_words_controller.rb` | FR-025 (4a12564, 9bf6c81) |
| `backend/app/domain/business/dish/dish/evaluation/command/evaluate_command.rb` | FR-011 (cdb8e27) |
| `backend/app/domain/business/dish/dish/evaluation/repository.rb` | FR-011 (cdb8e27) |
| `backend/app/domain/business/dish/meal/command/swap_meals_between_days_command.rb` | FR-018 partial (25471fd, 3d832f5) |
| `backend/app/domain/business/food/README.md` | FR-034 (fcac860, b350923), RV-025 prebaseline (e793c79) |
| `backend/app/domain/business/food/dish/source/usecase/update_command.rb` | FR-004 (8adcbd6) |
| `backend/app/domain/business/food/dish/tag/usecase/add_tag_to_dish_command.rb` | FR-004 (8adcbd6) |
| `backend/app/domain/business/food/dish/usecase/dish_searcher.rb` | FR-007 (3751b09), CR-001 (ddfef5a, 8e14b47) |
| `backend/app/domain/business/food/dish/usecase/update_command.rb` | FR-004 (8adcbd6) |
| `backend/app/domain/business/food/dish/word/usecase/add_command.rb` | FR-024 (9b1df0a, 5631105), RV-014 prebaseline (63e8bda) |
| `backend/app/domain/business/food/dish/word/usecase/reflect_latest_normalize_word_command.rb` | FR-024 (9b1df0a, 5631105), CR-002 (30c86bb, c29f76d) |
| `backend/app/domain/business/food/dish/word/usecase/remove_command.rb` | FR-024 (9b1df0a, 5631105) |
| `backend/app/domain/business/food/dish/word/usecase/update_command.rb` | FR-024 (9b1df0a, 5631105), RV-014 prebaseline (63e8bda) |
| `backend/app/domain/business/food/meal/factory.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/frame/entry/usecase/add_command.rb` | FR-008 (a2ca053) |
| `backend/app/domain/business/food/meal/frame/entry/usecase/fill_with_meal_command.rb` | FR-008 (a2ca053) |
| `backend/app/domain/business/food/meal/frame/entry/usecase/remove_command.rb` | FR-005 (f7b3e68) |
| `backend/app/domain/business/food/meal/frame/pattern/entry/usecase/add_command.rb` | FR-010 (86ab57e) |
| `backend/app/domain/business/food/meal/frame/pattern/usecase/remove_command.rb` | FR-006 (d34ce8c) |
| `backend/app/domain/business/food/meal/frame/pattern/usecase/update_command.rb` | FR-006 (d34ce8c) |
| `backend/app/domain/business/food/meal/frame/usecase/remove_command.rb` | FR-005 (f7b3e68) |
| `backend/app/domain/business/food/meal/frame/usecase/update_command.rb` | FR-005 (f7b3e68) |
| `backend/app/domain/business/food/meal/frame_entry/root.rb` | FR-034 (fcac860, b350923) |
| `backend/app/domain/business/food/meal/frame_entry/usecase/add_command.rb` | FR-008 (a2ca053), FR-034 (fcac860, b350923) |
| `backend/app/domain/business/food/meal/frame_entry/usecase/fill_with_meal_command.rb` | FR-008 (a2ca053) |
| `backend/app/domain/business/food/meal/frame_entry/usecase/remove_command.rb` | FR-034 (fcac860, b350923) |
| `backend/app/domain/business/food/meal/policy/attach_dish_policy.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/postponed/factory.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/postponed/usecase/postponed_meals_finder.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/postponed/usecase/remove_command.rb` | CR-004 (02e2caf, f9a6359) |
| `backend/app/domain/business/food/meal/root.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/usecase/date_meals_finder.rb` | FR-009 (9528fa1) |
| `backend/app/domain/business/food/meal/usecase/remove_command.rb` | FR-003 (f440ac4) |
| `backend/app/domain/business/food/meal/usecase/swap_meals_between_days_command.rb` | FR-002 (affd7ec, 03e4828), FR-018 partial (25471fd, 3d832f5) |
| `backend/app/domain/business/food/meal/usecase/update_command.rb` | FR-003 (f440ac4) |
| `backend/app/graphql/mutations/dish/update_dish.rb` | FR-012 (ceb1da7, 2aae46f), RV-013 prebaseline (37272af) |
| `backend/app/graphql/mutations/dish/update_dish_with_new_source.rb` | FR-012 (ceb1da7, 2aae46f), RV-013 prebaseline (37272af) |
| `backend/app/graphql/mutations/meal/frame/pattern/add_meal_frame_pattern.rb` | FR-033 (65dc499) |
| `backend/app/graphql/mutations/meal/frame/pattern/delete_meal_frame_pattern.rb` | FR-006 (d34ce8c) |
| `backend/app/graphql/mutations/meal/frame/pattern/update_meal_frame_pattern.rb` | FR-006 (d34ce8c), FR-033 (65dc499) |
| `backend/app/graphql/mutations/meal/postponed/postpone_meal.rb` | CR-004 (02e2caf, f9a6359) |
| `backend/app/graphql/mutations/meal/postponed/schedule_postponed_meal.rb` | CR-004 (02e2caf, f9a6359) |
| `backend/app/graphql/mutations/meal/update_meal_with_new_dish.rb` | FR-022 (5b54e45, 6b6c473), RV-013 prebaseline (37272af) |
| `backend/app/graphql/sources/meal_frame_pattern_entries.rb` | FR-010 (86ab57e), RV-026 prebaseline (b859f23) |
| `backend/app/graphql/sources/meal_frames.rb` | FR-010 (86ab57e), RV-026 prebaseline (b859f23) |
| `backend/app/graphql/types/input/meal/frame/pattern/meal_frame_pattern_entry_input.rb` | FR-033 (65dc499) |
| `backend/app/graphql/types/output/dish/essential_dish.rb` | FR-013 (fb59312, afb5720) |
| `backend/app/graphql/types/output/meal/frame/pattern/meal_frame_pattern_entry_for_list.rb` | FR-010 (86ab57e), RV-026 prebaseline (b859f23) |
| `backend/app/graphql/types/output/meal/frame/pattern/meal_frame_pattern_for_list.rb` | FR-010 (86ab57e), RV-026 prebaseline (b859f23) |
| `backend/app/models/dish.rb` | CR-002 (30c86bb, c29f76d) |
| `backend/app/models/dish_tag.rb` | CR-002 (30c86bb, c29f76d) |
| `backend/app/models/meal.rb` | FR-002 (03e4828) |
| `backend/app/views/admin/food/dish/word/normalize_words/index.html.erb` | FR-025 (4a12564, 9bf6c81) |
| `backend/spec/domain/business/dish/dish/evaluation/command/ownership_spec.rb` | FR-011 (cdb8e27) |
| `backend/spec/domain/business/dish/meal/command/swap_meals_between_days_command_spec.rb` | FR-018 partial (3d832f5) |
| `backend/spec/domain/business/food/dish/ownership_spec.rb` | FR-004 (8adcbd6) |
| `backend/spec/domain/business/food/dish/usecase/dish_searcher_spec.rb` | FR-007 (3751b09), CR-001 (ddfef5a, 8e14b47) |
| `backend/spec/domain/business/food/dish/word/usecase/atomic_reflection_spec.rb` | FR-024 (9b1df0a, 5631105) |
| `backend/spec/domain/business/food/meal/dish_ownership_spec.rb` | FR-009 (9528fa1) |
| `backend/spec/domain/business/food/meal/frame/entry/ownership_spec.rb` | FR-008 (a2ca053) |
| `backend/spec/domain/business/food/meal/frame/ownership_spec.rb` | FR-005 (f7b3e68) |
| `backend/spec/domain/business/food/meal/frame/pattern/usecase/remove_command_spec.rb` | FR-006 (d34ce8c) |
| `backend/spec/domain/business/food/meal/frame/pattern/usecase/update_command_spec.rb` | FR-006 (d34ce8c) |
| `backend/spec/domain/business/food/meal/frame_entry/compatibility_spec.rb` | FR-034 (fcac860, b350923) |
| `backend/spec/domain/business/food/meal/policy/attach_dish_policy_spec.rb` | FR-009 (9528fa1) |
| `backend/spec/domain/business/food/meal/usecase/swap_meals_between_days_command_spec.rb` | FR-002 (affd7ec), FR-018 partial (3d832f5) |
| `backend/spec/graphql/mutation/dish/existing_tag_update_spec.rb` | CR-002 (30c86bb, c29f76d) |
| `backend/spec/graphql/mutation/dish/optional_arguments_spec.rb` | FR-012 (ceb1da7, 2aae46f) |
| `backend/spec/graphql/mutation/meal/frame/pattern/add_meal_frame_pattern_spec.rb` | FR-033 (65dc499) |
| `backend/spec/graphql/mutation/meal/frame/pattern/frame_ownership_spec.rb` | FR-010 (86ab57e) |
| `backend/spec/graphql/mutation/meal/frame/pattern/ownership_spec.rb` | FR-006 (d34ce8c) |
| `backend/spec/graphql/mutation/meal/frame/pattern/update_meal_frame_pattern_spec.rb` | FR-033 (65dc499) |
| `backend/spec/graphql/mutation/meal/frame_entry/fill_meal_frame_entry_spec.rb` | FR-008 (a2ca053) |
| `backend/spec/graphql/mutation/meal/frame_entry/registration_ownership_spec.rb` | FR-008 (a2ca053) |
| `backend/spec/graphql/mutation/meal/ownership_spec.rb` | FR-003 (f440ac4) |
| `backend/spec/graphql/mutation/meal/postponed/conversion_atomicity_spec.rb` | CR-004 (02e2caf, f9a6359) |
| `backend/spec/graphql/mutation/meal/update_meal_without_source_spec.rb` | FR-022 (5b54e45, 6b6c473) |
| `backend/spec/graphql/query/dish/effort_level_output_spec.rb` | FR-013 (fb59312, afb5720) |
| `backend/spec/graphql/types/input/meal/frame/pattern/meal_frame_pattern_entry_input_spec.rb` | FR-033 (65dc499) |
| `backend/spec/models/dish_tag_replacement_spec.rb` | CR-002 (30c86bb, c29f76d) |
| `backend/spec/requests/admin/food/dish/word/normalize_words_spec.rb` | FR-025 (4a12564, 9bf6c81) |
| `backend/spec_mysql/meal_conversion_concurrency_spec.rb` | CR-004 (02e2caf, f9a6359) |
| `backend/spec_mysql/mysql_spec_helper.rb` | CR-004 (02e2caf, f9a6359) |
| `frontend/src/app/logical-history.spec.tsx` | FR-020 (d8afcf0, 4f788d7) |
| `frontend/src/app/logical-history.tsx` | FR-020 (d8afcf0, 4f788d7) |
| `frontend/src/components/calendar/calendarComponents/Calendar/index.tsx` | FR-015 partial (c05d21d, 1cf58d6) |
| `frontend/src/components/calendar/calendarComponents/Calendar/refreshContract.spec.tsx` | FR-015 partial (c05d21d, 1cf58d6) |
| `frontend/src/components/calendar/calendarComponents/operationComponents/SwapMeals/useSwapMealsMode.ts` | FR-014 (601d722, 8fbaf80), RV-015 prebaseline (e432509) |
| `frontend/src/components/calendar/calendarComponents/useCalendarMode.spec.ts` | FR-014 (601d722, 8fbaf80), RV-015 prebaseline (e432509) |
| `frontend/src/components/calendar/useRefreshCalendarData.spec.tsx` | FR-015 partial (c05d21d, 1cf58d6) |
| `frontend/src/components/calendar/useRefreshCalendarData.tsx` | FR-015 partial (c05d21d, 1cf58d6) |
| `frontend/src/components/dish/DishForm/DishForm/DishFormOfOnlyDishFields.tsx` | FR-013 (fb59312, afb5720) |
| `frontend/src/components/dish/DishForm/DishForm/SelectEffortLevel.tsx` | FR-013 (fb59312, afb5720) |
| `frontend/src/components/dish/DishForm/DishForm/index.tsx` | FR-013 (fb59312, afb5720) |
| `frontend/src/components/dish/DishForm/EditDish.spec/effortLevelRetention.spec.tsx` | FR-013 (fb59312, afb5720) |
| `frontend/src/components/dish/DishSearchPanel/debounce.spec.tsx` | FR-016 (5319fbd, d1efd8f) |
| `frontend/src/components/dish/DishSearchPanel/index.tsx` | FR-016 (5319fbd, d1efd8f) |
| `frontend/src/components/meal/MealForm/EditMeal.spec.tsx` | FR-022 (5b54e45, 6b6c473) |
| `frontend/src/components/meal/frame/pattern/MealFramePatternEditor.spec.tsx` | FR-017 (62359ad, ea3b9f1), RV-012 prebaseline (7452e09) |
| `frontend/src/components/meal/frame/pattern/MealFramePatternFields.tsx` | FR-017 (62359ad, ea3b9f1), RV-012 prebaseline (7452e09) |
| `frontend/src/features/calendar/calendarDateFromPath.spec.ts` | FR-021 (c240b94, e21a44f), RV-029 prebaseline (e63166c) |
| `frontend/src/features/calendar/calendarDateFromPath.ts` | FR-021 (c240b94, e21a44f), RV-029 prebaseline (e63166c) |
| `frontend/src/features/dish/dishInputConversion.spec.ts` | FR-022 (5b54e45, 6b6c473), RV-001 prebaseline (a2191d3) |
| `frontend/src/features/dish/fetchDishQuery.ts` | FR-013 (fb59312, afb5720) |
| `frontend/src/features/dish/normalizeFunctions.ts` | FR-022 (5b54e45, 6b6c473), RV-001 prebaseline (a2191d3) |
| `frontend/src/features/meal/fetchMealQuery.ts` | FR-013 (fb59312, afb5720) |
| `frontend/src/features/meal/frame/pattern/addMealFramePatternMutation.ts` | FR-032 (5a2fd44) |
| `frontend/src/features/meal/frame/pattern/schema.spec.ts` | FR-032 (5a2fd44) |
| `frontend/src/features/meal/frame/pattern/schema.ts` | FR-032 (5a2fd44) |
| `frontend/src/features/meal/frame/pattern/updateMealFramePatternMutation.ts` | FR-032 (5a2fd44) |
| `frontend/src/features/meal/updateMealMutation.ts` | FR-022 (5b54e45, 6b6c473), RV-001 prebaseline (a2191d3) |
| `frontend/src/features/utils/mutationUtils.spec.tsx` | FR-014 (601d722, 8fbaf80) |
| `frontend/src/features/utils/mutationUtils.ts` | FR-014 (601d722, 8fbaf80) |
| `frontend/src/lib/graphql/generated/graphql.schema.json` | FR-013 (fb59312, afb5720), FR-022 (5b54e45, 6b6c473) |
| `frontend/src/lib/graphql/generated/graphql.ts` | FR-013 (fb59312, afb5720), FR-022 (5b54e45, 6b6c473) |
| `infrastructure/terraform/modules/github_oidc/main.tf` | FR-026 (df42ad7, 6cbfee5) |
| `infrastructure/terraform/modules/github_oidc/plan_policy.spec.mjs` | FR-026 (df42ad7, 6cbfee5) |
| `scripts/github/backend_deploy.spec.mjs` | FR-029 (d3e4515, b42acb9) |
| `scripts/github/frontend_build_filter.spec.mjs` | FR-030 (a871b4c, de54d5e) |
| `scripts/review_backend/start.sh` | FR-027 public-IP (7772f90, a530b10) |
| `scripts/review_backend/start.spec.mjs` | FR-027 public-IP (7772f90, a530b10) |
