#' Replace single integers strictly below 100 with missing values
#'
#' @description
#' `na_if_single_lt100()` scans a character vector and replaces values that are
#' **exactly one integer** (digits only, no other characters) and **strictly lower
#' than 100** with `NA`.
#'
#' All other values are returned unchanged, including:
#' - `NA` values,
#' - integers `>= 100`,
#' - strings that contain multiple numbers (e.g. `"15;101"`),
#' - strings containing non-digit characters (e.g. `"ser"`).
#'
#' The function is vectorised and intended for use inside `dplyr::mutate()`.
#'
#' @param x A character vector.
#'
#' @return A character vector of the same length as `x`.
#'
#' @examples
#' x <- c(NA, "15", "99", "100", "015", "15;101", "ser", "101")
#' na_if_single_lt100(x)
#'
#' df <- tibble::tibble(x = x)
#' dplyr::mutate(df, y = na_if_single_lt100(x))
#'
#' @export
na_if_single_lt100 <- function(x) {
  if (!is.character(x)) {
    rlang::abort("`x` must be a character vector.")
  }

  out <- x

  # Exactly one integer (digits only), no other characters
  is_single_int <- !is.na(x) & grepl("^\\d+$", x)
  if (!any(is_single_int)) {
    return(out)
  }

  # Full-length integer vector (NA elsewhere)
  v <- rep.int(NA_integer_, length(x))
  v[is_single_int] <- suppressWarnings(as.integer(x[is_single_int]))

  out[is_single_int & !is.na(v) & (v < 100L)] <- NA_character_
  out
}
