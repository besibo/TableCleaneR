#' Normalize a number list stored as a character string
#'
#' @description
#' `normalize_num_list()` standardizes strings that contain one or more integers.
#'
#' Input is accepted only if it contains **digits** and optional **authorized separators**:
#' spaces, `;`, `-`, `,`, and the word `"ET"` (case-insensitive, as a token).
#' If any other character is present (e.g. letters like `"ser"`, punctuation like `"="`),
#' the function returns `NA`.
#'
#' Cases:
#' - `NA` -> `NA`.
#' - A single integer (e.g. `"15"`) -> unchanged.
#' - A semicolon-separated list with no spaces (e.g. `"15;101;100"`) -> unchanged.
#' - Otherwise, integers are extracted and rejoined with `sep`.
#'   If no integer is found, returns `NA`.
#'
#' @param x A character vector.
#' @param sep Separator used to join multiple integers after normalization.
#'   Default is `";"`.
#' @param unique Logical. If `TRUE`, duplicated integers are removed while preserving
#'   first occurrence order. Default is `TRUE`.
#'
#' @return A character vector of the same length as `x`.
#'
#' @examples
#' normalize_num_list(c(NA, "15", "15;101", "15 ET 101", "15-100-101", "ser"))
#'
#' @export
normalize_num_list <- function(x, sep = ";", unique = TRUE) {
  if (!is.character(x)) {
    rlang::abort("`x` must be a character vector.")
  }
  if (!is.character(sep) || length(sep) != 1 || is.na(sep)) {
    rlang::abort("`sep` must be a non-missing single string.")
  }
  if (!is.logical(unique) || length(unique) != 1 || is.na(unique)) {
    rlang::abort("`unique` must be a single TRUE/FALSE value.")
  }

  out <- x

  is_single_int <- !is.na(x) & grepl("^\\d+$", x)
  is_norm_list <- !is.na(x) & grepl("^\\d+(;\\d+)+$", x)

  needs_work <- !(is_single_int | is_norm_list) & !is.na(x)
  if (!any(needs_work)) {
    return(out)
  }

  xs <- x[needs_work]

  # 1) Reject any character outside: digits, space, ; - , and the token ET
  # Remove allowed "ET" tokens first, then check remaining characters.
  xs_no_et <- gsub("\\bET\\b", "", xs, ignore.case = TRUE, perl = TRUE)

  # After removing ET, only digits/spaces/;-, are allowed.
  is_allowed <- grepl("^[0-9\\s;,-]*$", xs_no_et, perl = TRUE)

  # Anything not allowed -> NA
  invalid <- !is_allowed
  xs_valid <- xs[!invalid]

  # 2) For valid strings, extract integers
  matches <- gregexpr("\\d+", xs_valid, perl = TRUE)
  nums_list <- regmatches(xs_valid, matches)

  rebuilt_valid <- vapply(
    seq_along(nums_list),
    function(i) {
      nums <- nums_list[[i]]

      if (length(nums) == 0) {
        return(NA_character_)
      }
      if (unique) {
        nums <- nums[!duplicated(nums)]
      }

      if (length(nums) == 1) {
        return(nums[[1]])
      }
      paste(nums, collapse = sep)
    },
    character(1)
  )

  rebuilt <- xs
  rebuilt[invalid] <- NA_character_
  rebuilt[!invalid] <- rebuilt_valid

  out[needs_work] <- rebuilt
  out
}
