# Collapse data and keep only key groups where concatenation occurs

`collapse_concat_only()` returns a collapsed table (one row per key
combination, as in [`collapse_by_keys()`](collapse_by_keys.md)), but
restricted to key groups where concatenation is actually needed for at
least one column selected by `.concat`.

"Concatenation is needed" means: within a key group, at least one
`.concat` column has more than one distinct value (respecting `na_rm`).

## Usage

``` r
collapse_concat_only(
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

  A tidyselect specification of columns that may be concatenated. Must
  not be `NULL`.

- sep:

  String used to separate concatenated values.

- na_rm:

  Logical. If `TRUE`, ignore `NA` values for distinctness checks and
  concatenation.

- warn:

  Logical. Passed to [`collapse_by_keys()`](collapse_by_keys.md). If
  `TRUE`, warns about non-`.concat` divergent columns replaced by `NA`.

## Value

A tibble containing one row per key group, restricted to groups where at
least one `.concat` column required concatenation.

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

# Keep only the collapsed rows where commentaire/source_info needed concatenation
out <- df %>%
  collapse_concat_only(
    exam.num_collec, mat.matrice, spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE
  )
#> Warning: Divergent columns replaced by NA: value

out
#> # A tibble: 1 × 6
#>   exam.num_collec mat.matrice spe.denomination commentaire    source_info value
#>             <dbl> <chr>       <chr>            <chr>          <chr>       <dbl>
#> 1               1 SER         E. coli          first | repeat labA | labB    NA
```
