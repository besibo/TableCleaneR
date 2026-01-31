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


#' Collapse data and keep only key groups where concatenation occurs
#'
#' @description
#' `collapse_concat_only()` returns a collapsed table (one row per key combination,
#' as in `collapse_by_keys()`), but restricted to key groups where concatenation is
#' actually needed for at least one column selected by `.concat`.
#'
#' "Concatenation is needed" means: within a key group, at least one `.concat` column
#' has more than one distinct value (respecting `na_rm`).
#'
#' @param .data A data frame or tibble.
#' @param ... Key columns defining groups (tidyeval).
#' @param .concat A tidyselect specification of columns that may be concatenated. Must not be `NULL`.
#' @param sep String used to separate concatenated values.
#' @param na_rm Logical. If `TRUE`, ignore `NA` values for distinctness checks and concatenation.
#' @param warn Logical. Passed to `collapse_by_keys()`. If `TRUE`, warns about non-`.concat` divergent
#'   columns replaced by `NA`.
#'
#' @return A tibble containing one row per key group, restricted to groups where at least one `.concat`
#'   column required concatenation.
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
#' # Keep only the collapsed rows where commentaire/source_info needed concatenation
#' out <- df %>%
#'   collapse_concat_only(
#'     exam.num_collec, mat.matrice, spe.denomination,
#'     .concat = c(commentaire, source_info),
#'     sep = " | ",
#'     na_rm = TRUE
#'   )
#'
#' out
#'
#' @export
collapse_concat_only <- function(
  .data,
  ...,
  .concat = NULL,
  sep = " ; ",
  na_rm = TRUE,
  warn = TRUE
) {
  stopifnot(is.data.frame(.data))

  # --- resolve keys (supports bare names + tidyselect) ---
  key_names <- .tc_resolve_keys(.data, ...)

  # .concat captured without evaluation; resolved via tidyselect
  concat_q <- rlang::enquo(.concat)
  if (rlang::quo_is_null(concat_q)) {
    rlang::abort(
      "`.concat` must be provided (tidyselect) to detect concatenated groups."
    )
  }
  concat_names <- names(tidyselect::eval_select(concat_q, .data))
  if (length(concat_names) == 0) {
    return(tibble::as_tibble(.data[0, , drop = FALSE]))
  }

  overlap <- intersect(key_names, concat_names)
  if (length(overlap) > 0) {
    rlang::abort(paste0(
      "Key columns cannot be in `.concat`: ",
      paste(overlap, collapse = ", ")
    ))
  }

  # Identify key groups where concatenation would occur
  affected_keys <- .data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(key_names))) %>%
    dplyr::summarise(
      .concat_affected = dplyr::if_any(
        dplyr::all_of(concat_names),
        ~ {
          x <- if (na_rm) .x[!is.na(.x)] else .x
          dplyr::n_distinct(x) > 1
        }
      ),
      .groups = "drop"
    ) %>%
    dplyr::filter(.data$.concat_affected) %>%
    dplyr::select(dplyr::all_of(key_names))

  if (nrow(affected_keys) == 0) {
    # Return empty tibble with same columns as the merged output would have
    merged_all <- collapse_by_keys(
      .data,
      ...,
      .concat = !!concat_q,
      sep = sep,
      na_rm = na_rm,
      warn = warn
    )
    return(merged_all[0, , drop = FALSE])
  }

  # Merge all, then keep only affected groups
  merged_all <- collapse_by_keys(
    .data,
    ...,
    .concat = !!concat_q,
    sep = sep,
    na_rm = na_rm,
    warn = warn
  )

  merged_all %>%
    dplyr::semi_join(affected_keys, by = key_names) %>%
    tibble::as_tibble()
}
