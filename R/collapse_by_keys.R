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


#' Collapse duplicate key groups, concatenating selected columns and replacing other divergences with NA
#'
#' @description
#' `collapse_by_keys()` enforces uniqueness of key combinations by collapsing (merging)
#' rows that share the same keys (provided in `...`). The output contains exactly one
#' row per unique key combination.
#'
#' For each non-key column within a key group:
#' \itemize{
#'   \item If the column has a single distinct value within the group (optionally ignoring `NA`
#'   according to `na_rm`), that value is kept.
#'   \item If the column has multiple distinct values:
#'   \itemize{
#'     \item If the column is selected by `.concat`, the distinct values are concatenated
#'     as a single character string using `sep` (after optional `NA` removal).
#'     \item Otherwise, the column is set to `NA` for that collapsed row (typed `NA` via `vctrs::vec_cast()`).
#'   }
#' }
#'
#' When `warn = TRUE`, the function emits a warning listing the non-key columns (excluding `.concat`)
#' that were divergent in at least one group and therefore were replaced by `NA` (for affected groups).
#'
#' @param .data A data frame or tibble.
#' @param ... Key columns defining groups that must be unique in the output. Uses tidyeval.
#' @param .concat Optional tidyselect specification of non-key columns whose divergent values should
#'   be concatenated. If `NULL` (default), no columns are concatenated.
#' @param sep String used to separate concatenated values.
#' @param na_rm Logical. If `TRUE`, ignore `NA` values when assessing distinctness within a group
#'   and when concatenating. If `FALSE`, `NA` participates in distinctness (i.e., `c("A", NA)` is divergent).
#' @param warn Logical. If `TRUE`, emit a warning listing columns (excluding keys and `.concat`)
#'   that were divergent in at least one group and were replaced by `NA`.
#'
#' @details
#' \strong{Type behavior}
#' \itemize{
#'   \item Columns selected in `.concat` return a character result when concatenation is needed.
#'   This may change the type of those columns in the output.
#'   \item For non-`.concat` columns, divergent groups are replaced by a typed `NA` using
#'   `vctrs::vec_cast(NA, x)` to preserve the column's type whenever possible.
#' }
#'
#' The output is an ungrouped tibble (`.groups = "drop"`).
#'
#' @return A tibble with one row per unique key combination.
#'
#' @examples
#' library(dplyr)
#' library(tibble)
#'
#' df <- tibble(
#'   exam.num_collec  = c(1, 1, 1, 2, 2),
#'   mat.matrice      = c("SER", "SER", "SER", "PLAS", "PLAS"),
#'   spe.denomination = c("E. coli", "E. coli", "E. coli", "S. aureus", "S. aureus"),
#'   result           = c("POS", "NEG", "POS", "NEG", "NEG"),
#'   value            = c(10, 10, 12, 5, 5),
#'   commentaire      = c("first", NA, "repeat", "ok", "ok"),
#'   source_info      = c("labA", "labA", "labB", "labC", NA),
#'   flag             = c(TRUE, TRUE, TRUE, FALSE, FALSE)
#' )
#'
#' # Collapse by keys:
#' # - concatenate selected text columns if needed
#' # - replace other divergent columns by NA
#' out <- df %>%
#'   collapse_by_keys(
#'     exam.num_collec, mat.matrice, spe.denomination,
#'     .concat = c(commentaire, source_info),
#'     sep = " | ",
#'     na_rm = TRUE,
#'     warn = TRUE
#'   )
#'
#' out
#'
#' @export
collapse_by_keys <- function(
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

  # --- capture .concat WITHOUT evaluating it ---
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

  non_key_cols <- setdiff(names(.data), key_names)
  na_cols <- setdiff(non_key_cols, concat_names)

  # --- warning on NA-replaced columns (only na_cols) ---
  if (warn && length(na_cols) > 0) {
    div_any <- .data %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(key_names))) %>%
      dplyr::summarise(
        dplyr::across(
          dplyr::all_of(na_cols),
          ~ {
            x <- if (na_rm) .x[!is.na(.x)] else .x
            dplyr::n_distinct(x) > 1
          }
        ),
        .groups = "drop"
      ) %>%
      dplyr::summarise(dplyr::across(dplyr::all_of(na_cols), any))

    divergent_cols <- names(div_any)[as.logical(div_any[1, , drop = TRUE])]
    if (length(divergent_cols) > 0) {
      rlang::warn(paste0(
        "Divergent columns replaced by NA: ",
        paste(divergent_cols, collapse = ", ")
      ))
    }
  }

  merge_vec <- function(x, do_concat) {
    x_chk <- if (na_rm) x[!is.na(x)] else x
    if (length(x_chk) == 0) {
      return(vctrs::vec_cast(NA, x))
    }

    ux <- unique(x_chk)
    if (length(ux) == 1) {
      return(ux[[1]])
    }

    if (do_concat) {
      return(paste(unique(as.character(x_chk)), collapse = sep))
    }
    vctrs::vec_cast(NA, x)
  }

  .data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(key_names))) %>%
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(non_key_cols),
        ~ merge_vec(.x, dplyr::cur_column() %in% concat_names)
      ),
      .groups = "drop"
    ) %>%
    tibble::as_tibble()
}
