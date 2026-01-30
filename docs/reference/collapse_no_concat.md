# Collapse data and keep only key groups where no concatenation is needed

`collapse_no_concat()` returns a collapsed table (one row per key
combination, as in [`collapse_by_keys()`](collapse_by_keys.md)), but
restricted to key groups where *no* concatenation would be needed for
columns selected by `.concat`.

"No concatenation is needed" means: within a key group, every `.concat`
column has at most one distinct value (respecting `na_rm`).

If `.concat` is `NULL`, the function returns the same result as
[`collapse_by_keys()`](collapse_by_keys.md) with `.concat = NULL` (i.e.,
no groups are excluded on the basis of concatenation).

## Usage

``` r
collapse_no_concat(
  .data,
  ...,
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

  Key columns defining groups (tidyeval).

- .concat:

  Optional tidyselect specification of columns used to assess whether
  concatenation would be needed. If `NULL`, no exclusion is performed.

- sep:

  String used to separate concatenated values (passed to
  [`collapse_by_keys()`](collapse_by_keys.md); only relevant if
  `.concat` is not `NULL` and a group is collapsed).

- na_rm:

  Logical. If `TRUE`, ignore `NA` values for distinctness checks and
  concatenation.

- warn:

  Logical. Passed to [`collapse_by_keys()`](collapse_by_keys.md). If
  `TRUE`, warns about non-`.concat` divergent columns replaced by `NA`.

## Value

A tibble containing one row per key group, restricted to groups where no
`.concat` column would require concatenation.

## Examples

``` r
library(dplyr)
library(tibble)

df <- tibble(
  exam.num_collec  = c(1, 1, 1, 2, 2),
  mat.matrice      = c("SER", "SER", "SER", "PLAS", "PLAS"),
  spe.denomination = c("E. coli", "E. coli", "E. coli", "S. aureus", "S. aureus"),
  commentaire      = c("first", NA, "repeat", "ok", "ok"),
  source_info      = c("labA", "labA", "labB", "labC", NA),
  value            = c(10, 10, 12, 5, 5)
)

# Keep only collapsed groups where commentaire/source_info do NOT require concatenation
ok <- df %>%
  collapse_no_concat(
    exam.num_collec, mat.matrice, spe.denomination,
    .concat = c(commentaire, source_info),
    na_rm = TRUE
  )
#> Warning: Divergent columns replaced by NA: value

ok
#> # A tibble: 1 × 6
#>   exam.num_collec mat.matrice spe.denomination commentaire source_info value
#>             <dbl> <chr>       <chr>            <chr>       <chr>       <dbl>
#> 1               2 PLAS        S. aureus        ok          labC            5
```
