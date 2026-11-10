# 全代碼健檢報告（自動產生）

由 `python3 tools/health_scan.py`（v3）產生（含遞移死碼不動點、`Type::method` 精確呼叫匹配、
排除自遞迴／`spec.mbt`／`facade.mbt`／`reexport_*`／`extend` 虛假引用、純函式體與私有助手 α 等價查重）。
此檔是**報告**，不是閘門；閘門仍是 `moon check --deny-warn` + `python3 tools/arch_check.py`。

## 0. 規模

| 項目 | 數量 |
|---|---|
| 掃描到的函式／方法定義 | 5810 |
| 完全無引用函式／方法（遞移死碼候選） | 0 |
| 完全無引用型別（`struct`/`enum`/`type`/`trait`） | 0 |
| 空殼列舉（`enum Foo {}`） | 0 |
| 完全相同或同包 α 等價函式體的重複組 | 0 |
| 結構極相近的重複組 | 4 |

## 1. 死碼候選（全倉零引用函式／方法／型別／空殼）

（無）

## 2. 完全相同或同包 α 等價的函式體

（無）

## 3. 結構極相近（同一組識別字集合，疑似複製貼上）

- 近似組（長度 318）：
  - `cubical/homotopy/homotopy_universal.mbt:53` `join_schema_at`
  - `cubical/homotopy/homotopy_universal.mbt:150` `wedge_schema_at`
- 近似組（長度 302）：
  - `cubical/kernel/schema.mbt:4453` `torus_schema`
  - `cubical/kernel/schema_extensions.mbt:710` `cube3_schema`
- 近似組（長度 275）：
  - `meta/instances/modules.mbt:261` `graph_dag`
  - `meta/instances/modules.mbt:280` `graph_dag_permuted`
- 近似組（長度 248）：
  - `algebra/poly_cube.mbt:70` `poly_insert_atom`
  - `algebra/poly_cube.mbt:93` `poly_drop_atom`

