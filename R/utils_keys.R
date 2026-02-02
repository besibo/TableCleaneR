.tc_resolve_keys <- function(.data, ..., .keys = NULL) {
  stopifnot(is.data.frame(.data))

  # .keys is expected to be a quosure (from enquo(.keys)), or NULL
  if (
    is.null(.keys) || rlang::quo_is_null(.keys) || rlang::quo_is_missing(.keys)
  ) {
    # Legacy path: bare column names in `...` only (symbols)
    key_syms <- rlang::ensyms(...)
    if (length(key_syms) == 0) {
      rlang::abort("Provide at least one key column in `...` or `.keys`.")
    }
    key_names <- vapply(key_syms, rlang::as_string, character(1))

    missing <- setdiff(key_names, names(.data))
    if (length(missing) > 0) {
      rlang::abort(paste0(
        "Key column(s) not found in `.data`: ",
        paste(missing, collapse = ", ")
      ))
    }
    return(key_names)
  }

  # If .keys evaluates to a character vector -> explicit names
  keys_val <- tryCatch(
    rlang::eval_tidy(.keys, data = NULL),
    error = function(e) NULL
  )

  if (is.character(keys_val)) {
    if (length(keys_val) == 0) {
      rlang::abort("`.keys` resulted in 0 names.")
    }
    if (anyNA(keys_val) || any(!nzchar(keys_val))) {
      rlang::abort("`.keys` contains missing/empty names.")
    }

    missing <- setdiff(keys_val, names(.data))
    if (length(missing) > 0) {
      rlang::abort(paste0(
        "Key column(s) not found in `.data`: ",
        paste(missing, collapse = ", ")
      ))
    }
    return(keys_val)
  }

  # Otherwise treat .keys as tidyselect expression
  key_names <- names(tidyselect::eval_select(.keys, .data))
  if (length(key_names) == 0) {
    rlang::abort("Key selection resulted in 0 columns.")
  }
  key_names
}
