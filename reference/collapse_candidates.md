# Extract original rows from key groups where concatenation would be required

`collapse_candidates()` identifies key groups (defined by `...`) where
at least one column selected by `.concat` contains more than one
distinct value within the group (respecting `na_rm`). It returns the
*original input rows* belonging to those groups.

This is useful for auditing or reviewing duplicates before applying
[`collapse_by_keys()`](https://besibo.github.io/TableCleaneR/reference/collapse_by_keys.md).

## Usage

``` r
collapse_candidates(.data, ..., .concat = NULL, na_rm = TRUE)
```

## Arguments

- .data:

  A data frame or tibble.

- ...:

  Key columns defining groups (tidyeval).

- .concat:

  A tidyselect specification of columns to check for divergence (and
  hence potential concatenation). Must not be `NULL`.

- na_rm:

  Logical. If `TRUE`, ignore `NA` values when assessing distinctness
  within a group. If `FALSE`, `NA` participates in distinctness.

## Value

A tibble containing only the input rows that belong to key groups where
at least one `.concat` column is divergent (i.e., concatenation would be
needed).

## Examples

``` r
library(dplyr)
library(tibble)

df <- tibble(
  exam.num_collec  = c(1, 1, 1, 2, 2),
  mat.matrice      = c("SER", "SER", "SER", "PLAS", "PLAS"),
  spe.denomination = c("E. coli", "E. coli", "E. coli", "S. aureus", "S. aureus"),
  commentaire      = c("first", NA, "repeat", "ok", "ok"),
  source_info      = c("labA", "labA", "labB", "labC", NA)
)

# Return the original rows from groups where commentaire and/or source_info would be concatenated
candidates <- df %>%
  collapse_candidates(
    exam.num_collec, mat.matrice, spe.denomination,
    .concat = c(commentaire, source_info),
    na_rm = TRUE
  )

candidates
#> # A tibble: 3 × 5
#>   exam.num_collec mat.matrice spe.denomination commentaire source_info
#>             <dbl> <chr>       <chr>            <chr>       <chr>      
#> 1               1 SER         E. coli          first       labA       
#> 2               1 SER         E. coli          NA          labA       
#> 3               1 SER         E. coli          repeat      labB       
```
