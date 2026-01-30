#' Collapse data and keep only key groups where no concatenation is needed
#'
#' @description
#' `collapse_no_concat()` returns a collapsed table (one row per key combination,
#' as in `collapse_by_keys()`), but restricted to key groups where \emph{no} concatenation
#' would be needed for columns selected by `.concat`.
#'
#' "No concatenation is needed" means: within a key group, every `.concat` column has at most
#' one distinct value (respecting `na_rm`).
#'
#' If `.concat` is `NULL`, the function returns the same result as `collapse_by_keys()` with
#' `.concat = NULL` (i.e., no groups are excluded on the basis of concatenation).
#'
#' @param .data A data frame or tibble.
#' @param ... Key columns defining groups (tidyeval).
#' @param .concat Optional tidyselect specification of columns used to assess whether concatenation
#'   would be needed. If `NULL`, no exclusion is performed.
#' @param sep String used to separate concatenated values (passed to `collapse_by_keys()`; only relevant
#'   if `.concat` is not `NULL` and a group is collapsed).
#' @param na_rm Logical. If `TRUE`, ignore `NA` values for distinctness checks and concatenation.
#' @param warn Logical. Passed to `collapse_by_keys()`. If `TRUE`, warns about non-`.concat` divergent
#'   columns replaced by `NA`.
#'
#' @return A tibble containing one row per key group, restricted to groups where no `.concat` column
#'   would require concatenation.
#'
#' @examples
#' library(dplyr)
#' library(tibble)
#'
#' df <- tibble(
#'   exam.num_collec  = c(1, 1, 1, 2, 2),
#'   mat.matrice      = c("SER", "SER", "SER", "PLAS", "PLAS"),
#'   spe.denomination = c("E. coli", "E. coli", "E. coli", "S. aureus", "S. aureus"),
#'   commentaire      = c("first", NA, "repeat", "ok", "ok"),
#'   source_info      = c("labA", "labA", "labB", "labC", NA),
#'   value            = c(10, 10, 12, 5, 5)
#' )
#'
#' # Keep only collapsed groups where commentaire/source_info do NOT require concatenation
#' ok <- df %>%
#'   collapse_no_concat(
#'     exam.num_collec, mat.matrice, spe.denomination,
#'     .concat = c(commentaire, source_info),
#'     na_rm = TRUE
#'   )
#'
#' ok
#'
#' @export
collapse_no_concat <- function(
  .data,
  ...,
  .concat = NULL,
  sep = " ; ",
  na_rm = TRUE,
  warn = TRUE
) {
  stopifnot(is.data.frame(.data))

  # --- keys (tidyeval) ---
  key_syms <- rlang::ensyms(...)
  if (length(key_syms) == 0) {
    rlang::abort("Provide at least one key column in `...`.")
  }
  key_names <- vapply(key_syms, rlang::as_string, character(1))

  missing_keys <- setdiff(key_names, names(.data))
  if (length(missing_keys) > 0) {
    rlang::abort(paste0(
      "Key column(s) not found in `.data`: ",
      paste(missing_keys, collapse = ", ")
    ))
  }

  # --- capture .concat WITHOUT evaluating it; resolve via tidyselect ---
  concat_q <- rlang::enquo(.concat)
  concat_names <- if (rlang::quo_is_null(concat_q)) {
    character(0)
  } else {
    names(tidyselect::eval_select(concat_q, .data))
  }

  overlap <- intersect(key_names, concat_names)
  if (length(overlap) > 0) {
    rlang::abort(paste0(
      "Key columns cannot be in `.concat`: ",
      paste(overlap, collapse = ", ")
    ))
  }

  # Compute full collapsed table (this also handles NA replacement warnings)
  merged_all <- collapse_by_keys(
    .data,
    ...,
    .concat = !!concat_q,
    sep = sep,
    na_rm = na_rm,
    warn = warn
  )

  # If no concat columns were specified/selected, nothing to exclude
  if (length(concat_names) == 0) {
    return(merged_all)
  }

  # Identify key groups where concatenation would occur
  affected_keys <- .data %>%
    dplyr::group_by(!!!key_syms) %>%
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(concat_names),
        ~ {
          x <- if (na_rm) .x[!is.na(.x)] else .x
          dplyr::n_distinct(x) > 1
        }
      ),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      .concat_affected = rowSums(dplyr::across(dplyr::all_of(concat_names))) > 0
    ) %>%
    dplyr::filter(.data$.concat_affected) %>%
    dplyr::select(dplyr::all_of(key_names))

  # Keep only groups NOT affected by concatenation
  merged_all %>%
    dplyr::anti_join(affected_keys, by = key_names) %>%
    tibble::as_tibble()
}
