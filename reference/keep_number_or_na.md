# Keep a single number from a string, otherwise return `NA`

`keep_number_or_na()` extracts digits from each element of a character
vector according to the following rules:

- If the string contains **exactly one** number (one contiguous run of
  digits), that number is returned (as character). This includes strings
  made only of digits (e.g. `"15"`) and strings where the number is
  mixed with letters or other characters (e.g. `"ID=15"`).

- If the string contains **no** number, the result is `NA`.

- If the string contains **more than one** number (e.g. `"15;101"`,
  `"abc12def34"`), the result is `NA`.

The function is vectorised and can be used inside
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
keep_number_or_na(x)
```

## Arguments

- x:

  A character vector.

## Value

A character vector of the same length as `x`.

## Examples

``` r
x <- c("15", "ID=15", "ser", NA, "15;101", "abc12def34")
keep_number_or_na(x)
#> [1] "15" "15" NA   NA   NA   NA  

df <- tibble::tibble(x = x)
dplyr::mutate(df, y = keep_number_or_na(x))
#> # A tibble: 6 × 2
#>   x          y    
#>   <chr>      <chr>
#> 1 15         15   
#> 2 ID=15      15   
#> 3 ser        NA   
#> 4 NA         NA   
#> 5 15;101     NA   
#> 6 abc12def34 NA   
```
