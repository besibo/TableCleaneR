test_that("collapse_by_keys collapses to one row per key and preserves keys", {
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
    result = c("POS", "NEG", "POS", "NEG", "NEG"), # divergent for key=1
    value = c(10, 10, 12, 5, 5), # divergent for key=1
    commentaire = c("first", NA, "repeat", "ok", "ok"), # concat target
    source_info = c("labA", "labA", "labB", "labC", NA), # concat target
    flag = c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )

  out <- collapse_by_keys(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE,
    warn = FALSE
  )

  # one row per key combination
  expect_equal(
    nrow(out),
    nrow(dplyr::distinct(df, exam.num_collec, mat.matrice, spe.denomination))
  )

  # keys present
  expect_true(all(
    c("exam.num_collec", "mat.matrice", "spe.denomination") %in% names(out)
  ))
})

test_that("collapse_by_keys replaces divergent non-.concat columns by NA and keeps constants", {
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
    result = c("POS", "NEG", "POS", "NEG", "NEG"), # divergent for key=1
    value = c(10, 10, 12, 5, 5), # divergent for key=1
    commentaire = c("first", NA, "repeat", "ok", "ok"), # concat target
    source_info = c("labA", "labA", "labB", "labC", NA), # concat target
    flag = c(TRUE, TRUE, TRUE, FALSE, FALSE)
  )

  out <- collapse_by_keys(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE,
    warn = FALSE
  )

  # pick each collapsed row by key
  row1 <- dplyr::filter(
    out,
    exam.num_collec == 1,
    mat.matrice == "SER",
    spe.denomination == "E. coli"
  )
  row2 <- dplyr::filter(
    out,
    exam.num_collec == 2,
    mat.matrice == "PLAS",
    spe.denomination == "S. aureus"
  )

  # divergent non-.concat columns become NA for group 1
  expect_true(is.na(row1$result))
  expect_true(is.na(row1$value))

  # constants preserved
  expect_identical(row1$flag, TRUE)
  expect_identical(row2$result, "NEG")
  expect_identical(row2$value, 5)
  expect_identical(row2$flag, FALSE)
})

test_that("collapse_by_keys concatenates .concat columns and respects na_rm", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1, 1),
    mat.matrice = c("SER", "SER", "SER"),
    spe.denomination = c("E. coli", "E. coli", "E. coli"),
    commentaire = c("first", NA, "repeat"),
    source_info = c("labA", "labA", "labB")
  )

  # na_rm = TRUE: NA ignored in concat/dedup
  out1 <- collapse_by_keys(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE,
    warn = FALSE
  )
  expect_equal(out1$commentaire, "first | repeat")
  expect_equal(out1$source_info, "labA | labB")

  # na_rm = FALSE: NA participates; concatenation should include NA if present
  out2 <- collapse_by_keys(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = commentaire,
    sep = " | ",
    na_rm = FALSE,
    warn = FALSE
  )
  # paste(c("first", NA, "repeat"), collapse=" | ") -> "first | NA | repeat"
  expect_equal(out2$commentaire, "first | NA | repeat")
})

test_that("collapse_by_keys emits a warning when non-.concat columns are divergent and warn=TRUE", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1),
    mat.matrice = c("SER", "SER"),
    spe.denomination = c("E. coli", "E. coli"),
    result = c("POS", "NEG"), # divergent non-.concat
    commentaire = c("a", "a") # constant .concat (or not selected)
  )

  expect_warning(
    collapse_by_keys(
      df,
      exam.num_collec,
      mat.matrice,
      spe.denomination,
      .concat = commentaire,
      warn = TRUE
    ),
    regexp = "Divergent columns replaced by NA"
  )

  expect_no_warning(
    collapse_by_keys(
      df,
      exam.num_collec,
      mat.matrice,
      spe.denomination,
      .concat = commentaire,
      warn = FALSE
    )
  )
})

test_that("collapse_candidates returns original rows only for key groups where .concat would be concatenated", {
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
    source_info = c("labA", "labA", "labB", "labC", NA)
  )

  cand <- collapse_candidates(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    na_rm = TRUE
  )

  # only the group with exam.num_collec == 1 should be returned
  expect_true(all(cand$exam.num_collec == 1))
  expect_equal(nrow(cand), 3)
})

test_that("collapse_concat_only returns only collapsed rows where concatenation occurred", {
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
    value = c(10, 10, 12, 5, 5)
  )

  out <- collapse_concat_only(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    sep = " | ",
    na_rm = TRUE,
    warn = FALSE
  )

  # only the key group where concatenation is needed (group 1)
  expect_equal(nrow(out), 1)
  expect_equal(out$exam.num_collec, 1)
  expect_equal(out$commentaire, "first | repeat")
  expect_equal(out$source_info, "labA | labB")
})

test_that("collapse_no_concat returns collapsed rows where no concatenation is needed", {
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
    value = c(10, 10, 12, 5, 5)
  )

  out <- collapse_no_concat(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = c(commentaire, source_info),
    na_rm = TRUE,
    warn = FALSE
  )

  # only group 2 remains
  expect_equal(nrow(out), 1)
  expect_equal(out$exam.num_collec, 2)
  expect_equal(out$commentaire, "ok")
  # na_rm=TRUE -> NA ignored, so labC only
  expect_equal(out$source_info, "labC")
})

test_that("tidyselect helpers work for .concat", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1, 1),
    mat.matrice = c("SER", "SER", "SER"),
    spe.denomination = c("E. coli", "E. coli", "E. coli"),
    commentaire = c("first", NA, "repeat"),
    source_info = c("labA", "labA", "labB")
  )

  out <- collapse_by_keys(
    df,
    exam.num_collec,
    mat.matrice,
    spe.denomination,
    .concat = tidyselect::starts_with("sour"),
    sep = " | ",
    na_rm = TRUE,
    warn = FALSE
  )

  expect_equal(out$source_info, "labA | labB")
  # commentaire was not in .concat and is divergent -> NA
  expect_true(is.na(out$commentaire))
})

test_that("error handling: missing keys, keys inside .concat, .concat required", {
  df <- tibble::tibble(
    exam.num_collec = c(1, 1),
    mat.matrice = c("SER", "SER"),
    spe.denomination = c("E. coli", "E. coli"),
    commentaire = c("a", "b")
  )

  # missing key column
  expect_error(
    collapse_by_keys(df, does_not_exist),
    regexp = "Key column\\(s\\) not found"
  )

  # keys cannot be in .concat
  expect_error(
    collapse_by_keys(
      df,
      exam.num_collec,
      mat.matrice,
      spe.denomination,
      .concat = exam.num_collec
    ),
    regexp = "Key columns cannot be in `.concat`"
  )

  # functions requiring .concat must error if NULL
  expect_error(
    collapse_candidates(df, exam.num_collec, mat.matrice, spe.denomination),
    regexp = "`.concat` must be provided"
  )
  expect_error(
    collapse_concat_only(df, exam.num_collec, mat.matrice, spe.denomination),
    regexp = "`.concat` must be provided"
  )
})
