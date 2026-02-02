# Collapse duplicate key groups, concatenating selected columns and replacing other divergences with NA

`collapse_by_keys()` enforces uniqueness of key combinations by
collapsing (merging) rows that share the same keys (provided in `...`).
The output contains exactly one row per unique key combination.

For each non-key column within a key group:

- If the column has a single distinct value within the group (optionally
  ignoring `NA` according to `na_rm`), that value is kept.

- If the column has multiple distinct values:

  - If the column is selected by `.concat`, the distinct values are
    concatenated as a single character string using `sep` (after
    optional `NA` removal).

  - Otherwise, the column is set to `NA` for that collapsed row (typed
    `NA` via
    [`vctrs::vec_cast()`](https://vctrs.r-lib.org/reference/vec_cast.html)).

When `warn = TRUE`, the function emits a warning listing the non-key
columns (excluding `.concat`) that were divergent in at least one group
and therefore were replaced by `NA` (for affected groups).

## Usage

``` r
collapse_by_keys(
  .data,
  ...,
  .keys = NULL,
  .concat = NULL,
  sep = " ; ",
  na_rm = TRUE,
  warn = TRUE
)
```

## Arguments

- .data:

  A data frame or tibble.

- ...:

  Key columns defining groups that must be unique in the output. Uses
  tidyeval.

- .keys:

  Optional alternative to …for programmatic key selection. Accepts
  either (i) a character vector of column names or (ii) a tidyselect
  expression evaluated in.data. If supplied, .keystakes precedence over…

- .concat:

  Optional tidyselect specification of non-key columns whose divergent
  values should be concatenated. If `NULL` (default), no columns are
  concatenated.

- sep:

  String used to separate concatenated values.

- na_rm:

  Logical. If `TRUE`, ignore `NA` values when assessing distinctness
  within a group and when concatenating. If `FALSE`, `NA` participates
  in distinctness (i.e., `c("A", NA)` is divergent).

- warn:

  Logical. If `TRUE`, emit a warning listing columns (excluding keys and
  `.concat`) that were divergent in at least one group and were replaced
  by `NA`.

## Value

A tibble with one row per unique key combination.

## Details

**Type behavior**

- Columns selected in `.concat` return a character result when
  concatenation is needed. This may change the type of those columns in
  the output.

- For non-`.concat` columns, divergent groups are replaced by a typed
  `NA` using `vctrs::vec_cast(NA, x)` to preserve the column's type
  whenever possible.

The output is an ungrouped tibble (`.groups = "drop"`).

## Examples

``` r
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
library(tibble)

df <- tibble(
  exam.num_collec  = c(1, 1, 1, 2, 2),
  mat.matrice      = c("SER", "SER", "SER", "PLAS", "PLAS"),
  spe.denomination = c("E. coli", "E. coli", "E. coli", "S. aureus", "S. aureus"),
  result           = c("POS", "NEG", "POS", "NEG", "NEG"),
  value            = c(10, 10, 12, 5, 5),
  commentaire      = c("first", NA, "repeat", "ok", "ok"),
  source_info      = c("labA", "labA", "labB", "labC", NA),
  flag             = c(TRUE, TRUE, TRUE, FALSE, FALSE)
)

# Collapse by keys:
# - concatenate selected text columns if needed
# - replace other divergent columns by NA
out <- df %>%
  collapse_by_keys(
    exam.num_collec, mat.matrice, spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE,
    warn = TRUE
  )
#> Warning: Divergent columns replaced by NA: result, value

out
#> # A tibble: 2 × 8
#>   exam.num_collec mat.matrice spe.denomination result value commentaire   
#>             <dbl> <chr>       <chr>            <chr>  <dbl> <chr>         
#> 1               1 SER         E. coli          NA        NA first | repeat
#> 2               2 PLAS        S. aureus        NEG        5 ok            
#> # ℹ 2 more variables: source_info <chr>, flag <lgl>
```
