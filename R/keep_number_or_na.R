#' Keep a single number from a string, otherwise return `NA`
#'
#' @description
#' `keep_number_or_na()` extracts digits from each element of a character vector
#' according to the following rules:
#'
#' - If the string contains **exactly one** number (one contiguous run of digits),
#'   that number is returned (as character).
#'   This includes strings made only of digits (e.g. `"15"`) and strings where
#'   the number is mixed with letters or other characters (e.g. `"ID=15"`).
#' - If the string contains **no** number, the result is `NA`.
#' - If the string contains **more than one** number (e.g. `"15;101"`,
#'   `"abc12def34"`), the result is `NA`.
#'
#' The function is vectorised and can be used inside `dplyr::mutate()`.
#'
#' @param x A character vector.
#'
#' @return A character vector of the same length as `x`.
#'
#' @examples
#' x <- c("15", "ID=15", "ser", NA, "15;101", "abc12def34")
#' keep_number_or_na(x)
#'
#' df <- tibble::tibble(x = x)
#' dplyr::mutate(df, y = keep_number_or_na(x))
#'
#' @export
keep_number_or_na <- function(x) {
  if (!is.character(x)) {
    rlang::abort("`x` must be a character vector.")
  }

  out <- rep(NA_character_, length(x))

  m <- gregexpr("\\d+", x, perl = TRUE)
  nums <- regmatches(x, m)

  has_one <- !is.na(x) & (lengths(nums) == 1L)
  out[has_one] <- vapply(nums[has_one], `[[`, character(1), 1)

  out
}
