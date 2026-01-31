if (!exists(".tc_resolve_keys", mode = "function")) {
  .tc_resolve_keys <- function(.data, ...) {
    qs <- rlang::enquos(...)
    if (length(qs) == 0) {
      rlang::abort("Provide at least one key column in `...`.")
    }

    exprs <- lapply(qs, rlang::get_expr)

    # Preserve the legacy error message for the common case: bare column names only.
    if (all(vapply(exprs, rlang::is_symbol, logical(1)))) {
      key_names <- vapply(exprs, rlang::as_string, character(1))
      missing_keys <- setdiff(key_names, names(.data))
      if (length(missing_keys) > 0) {
        rlang::abort(paste0(
          "Key column(s) not found in `.data`: ",
          paste(missing_keys, collapse = ", ")
        ))
      }
      return(key_names)
    }

    key_names <- names(tidyselect::eval_select(rlang::expr(c(!!!qs)), .data))
    if (length(key_names) == 0) {
      rlang::abort("Key selection resulted in 0 columns.")
    }
    key_names
  }
}


#' Extract original rows from key groups where concatenation would be required
#'
#' @description
#' `collapse_candidates()` identifies key groups (defined by `...`) where at least one
#' column selected by `.concat` contains more than one distinct value within the group
#' (respecting `na_rm`). It returns the \emph{original input rows} belonging to those groups.
#'
#' This is useful for auditing or reviewing duplicates before applying `collapse_by_keys()`.
#'
#' @param .data A data frame or tibble.
#' @param ... Key columns defining groups (tidyeval).
#' @param .concat A tidyselect specification of columns to check for divergence (and hence
#'   potential concatenation). Must not be `NULL`.
#' @param na_rm Logical. If `TRUE`, ignore `NA` values when assessing distinctness within a group.
#'   If `FALSE`, `NA` participates in distinctness.
#'
#' @return A tibble containing only the input rows that belong to key groups where at least one
#'   `.concat` column is divergent (i.e., concatenation would be needed).
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
#'   source_info      = c("labA", "labA", "labB", "labC", NA)
#' )
#'
#' # Return the original rows from groups where commentaire and/or source_info would be concatenated
#' candidates <- df %>%
#'   collapse_candidates(
#'     exam.num_collec, mat.matrice, spe.denomination,
#'     .concat = c(commentaire, source_info),
#'     na_rm = TRUE
#'   )
#'
#' candidates
#'
#' @export
collapse_candidates <- function(
  .data,
  ...,
  .concat = NULL,
  na_rm = TRUE
) {
  stopifnot(is.data.frame(.data))

  # --- resolve keys (supports bare names + tidyselect) ---
  key_names <- .tc_resolve_keys(.data, ...)

  # --- capture .concat WITHOUT evaluating it; resolve via tidyselect ---
  concat_q <- rlang::enquo(.concat)
  if (rlang::quo_is_null(concat_q)) {
    rlang::abort(
      "`.concat` must be provided (tidyselect) to detect affected groups."
    )
  }
  concat_names <- names(tidyselect::eval_select(concat_q, .data))

  if (length(concat_names) == 0) {
    # No concat columns selected => no group can be 'affected'
    return(tibble::as_tibble(.data[0, , drop = FALSE]))
  }

  overlap <- intersect(key_names, concat_names)
  if (length(overlap) > 0) {
    rlang::abort(paste0(
      "Key columns cannot be in `.concat`: ",
      paste(overlap, collapse = ", ")
    ))
  }

  # --- identify key combinations where any .concat column is truly divergent ---
  affected_keys <- .data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(key_names))) %>%
    dplyr::summarise(
      .affected = any(dplyr::across(
        dplyr::all_of(concat_names),
        ~ {
          x <- if (na_rm) .x[!is.na(.x)] else .x
          dplyr::n_distinct(x) > 1
        }
      )),
      .groups = "drop"
    ) %>%
    dplyr::filter(.data$.affected) %>%
    dplyr::select(dplyr::all_of(key_names))

  # --- return the original rows belonging to affected key groups ---
  .data %>%
    dplyr::semi_join(affected_keys, by = key_names) %>%
    tibble::as_tibble()
}
