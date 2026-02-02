# Normalize a number list stored as a character string

`normalize_num_list()` standardizes strings that contain one or more
integers.

Input is accepted only if it contains **digits** and optional
**authorized separators**: spaces, `;`, `-`, `,`, and the word `"ET"`
(case-insensitive, as a token). If any other character is present (e.g.
letters like `"ser"`, punctuation like `"="`), the function returns
`NA`.

Cases:

- `NA` -\> `NA`.

- A single integer (e.g. `"15"`) -\> unchanged.

- A semicolon-separated list with no spaces (e.g. `"15;101;100"`) -\>
  unchanged.

- Otherwise, integers are extracted and rejoined with `sep`. If no
  integer is found, returns `NA`.

## Usage

``` r
normalize_num_list(x, sep = ";", unique = TRUE)
```

## Arguments

- x:

  A character vector.

- sep:

  Separator used to join multiple integers after normalization. Default
  is `";"`.

- unique:

  Logical. If `TRUE`, duplicated integers are removed while preserving
  first occurrence order. Default is `TRUE`.

## Value

A character vector of the same length as `x`.

## Examples

``` r
normalize_num_list(c(NA, "15", "15;101", "15 ET 101", "15-100-101", "ser"))
#> [1] NA           "15"         "15;101"     "15;101"     "15;100;101"
#> [6] NA          
```
