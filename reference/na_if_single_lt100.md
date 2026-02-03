# Replace single integers strictly below 100 with missing values

`na_if_single_lt100()` scans a character vector and replaces values that
are **exactly one integer** (digits only, no other characters) and
**strictly lower than 100** with `NA`.

All other values are returned unchanged, including:

- `NA` values,

- integers `>= 100`,

- strings that contain multiple numbers (e.g. `"15;101"`),

- strings containing non-digit characters (e.g. `"ser"`).

The function is vectorised and intended for use inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
na_if_single_lt100(x)
```

## Arguments

- x:

  A character vector.

## Value

A character vector of the same length as `x`.

## Examples

``` r
x <- c(NA, "15", "99", "100", "015", "15;101", "ser", "101")
na_if_single_lt100(x)
#> [1] NA       NA       NA       "100"    NA       "15;101" "ser"    "101"   

df <- tibble::tibble(x = x)
dplyr::mutate(df, y = na_if_single_lt100(x))
#> # A tibble: 8 × 2
#>   x      y     
#>   <chr>  <chr> 
#> 1 NA     NA    
#> 2 15     NA    
#> 3 99     NA    
#> 4 100    100   
#> 5 015    NA    
#> 6 15;101 15;101
#> 7 ser    ser   
#> 8 101    101   
```
