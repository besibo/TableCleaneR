test_that(".keys (character vector) is equivalent to bare keys in ...", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1, 1, 2, 2),
    mat.matrice = c("SER", "SER", "SER", "PLAS", "PLAS"),
    spe.denomination = c(
      "E. coli",
      "E. coli",
      "E. coli",
      "S. aureus",
      "S. aureus"
    ),
    commentaire = c("first", NA, "repeat", "ok", "ok"),
    source_info = c("labA", "labA", "labB", "labC", NA),
    result = c("POS", "NEG", "POS", "NEG", "NEG"),
    value = c(10, 10, 12, 5, 5)
  )

  keys_chr <- c("exam.num_collec", "mat.matrice", "spe.denomination")

  out_dots <- df %>%
    collapse_by_keys(
      exam.num_collec,
      mat.matrice,
      spe.denomination,
      .concat = c(commentaire, source_info),
      sep = " | ",
      na_rm = TRUE,
      warn = FALSE
    )

  out_keys <- df %>%
    collapse_by_keys(
      .keys = keys_chr,
      .concat = c(commentaire, source_info),
      sep = " | ",
      na_rm = TRUE,
      warn = FALSE
    )

  # Same rows/cols and same content (order should also match given identical grouping)
  expect_identical(out_keys, out_dots)
})

test_that(".keys (tidyselect) works for keys selection", {
  df <- tibble::tibble(
    surv.a = c(1, 1, 2),
    exam.b = c("x", "x", "y"),
    mat.matrice = c("SER", "SER", "PLAS"),
    spe.denomination = c("E. coli", "E. coli", "S. aureus"),
    commentaire = c("first", "repeat", "ok"),
    source_info = c("labA", "labB", "labC"),
    value = c(10, 12, 5)
  )

  # Keys: all columns starting with surv. or exam. plus mat.matrice
  out <- df %>%
    collapse_candidates(
      .keys = tidyselect::matches("^(surv\\.|exam\\.)|^mat\\.matrice$"),
      .concat = c(commentaire, source_info),
      na_rm = TRUE
    )

  # In this data, group (surv.a=1, exam.b="x", mat.matrice="SER") has divergent .concat
  expect_true(all(out$surv.a == 1))
  expect_true(all(out$exam.b == "x"))
  expect_true(all(out$mat.matrice == "SER"))
  expect_equal(nrow(out), 2)
})

test_that(".keys takes precedence over ... when both are supplied", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1, 2, 2),
    mat.matrice = c("SER", "SER", "PLAS", "PLAS"),
    spe.denomination = c("E. coli", "E. coli", "S. aureus", "S. aureus"),
    commentaire = c("a", "b", "ok", "ok"),
    source_info = c("labA", "labB", "labC", "labC")
  )

  # If we key by exam.num_collec only, we will get 2 groups.
  # If we key by exam.num_collec + mat.matrice + spe.denomination, still 2 groups here,
  # but we want a precedence test that *changes grouping*.
  #
  # Create an extra row so that using only exam.num_collec merges two different mat.matrice values.
  df2 <- dplyr::bind_rows(
    df,
    tibble::tibble(
      exam.num_collec = 1,
      mat.matrice = "PLAS",
      spe.denomination = "E. coli",
      commentaire = "c",
      source_info = "labC"
    )
  )

  # Here, with keys = exam.num_collec, group 1 is larger (SER+PLAS mixed) and .concat diverges.
  # With keys = (exam.num_collec, mat.matrice, spe.denomination), group 1 splits and behaves differently.

  out_using_dots <- df2 %>%
    collapse_candidates(
      exam.num_collec, # dots keys
      .keys = c("exam.num_collec", "mat.matrice", "spe.denomination"), # should take precedence
      .concat = c(commentaire, source_info),
      na_rm = TRUE
    )

  # With .keys precedence, candidates should be only within the (1,SER,E. coli) group
  # (the (1,PLAS,E. coli) group has single row so no concat needed).
  expect_true(all(out_using_dots$exam.num_collec == 1))
  expect_true(all(out_using_dots$mat.matrice == "SER"))
  expect_true(all(out_using_dots$spe.denomination == "E. coli"))
})

test_that(".keys errors on missing columns and on empty selection", {
  df <- tibble::tibble(
    a = c(1, 1),
    b = c("x", "x"),
    commentaire = c("first", "repeat")
  )

  expect_error(
    collapse_candidates(df, .keys = c("a", "nope"), .concat = commentaire),
    regexp = "Key column\\(s\\) not found"
  )

  # Empty character vector
  expect_error(
    collapse_candidates(df, .keys = character(0), .concat = commentaire),
    regexp = "resulted in 0"
  )

  # Tidyselect that selects nothing
  expect_error(
    collapse_candidates(
      df,
      .keys = tidyselect::matches("^does_not_match$"),
      .concat = commentaire
    ),
    regexp = "Key selection resulted in 0"
  )
})
