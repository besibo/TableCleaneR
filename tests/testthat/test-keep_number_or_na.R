test_that("keep_number_or_na returns the single number when exactly one digit run is present", {
  x <- c("15", "ID=15", "  007  ", "abc000def", "0")
  expect_identical(
    keep_number_or_na(x),
    c("15", "15", "007", "000", "0")
  )
})

test_that("keep_number_or_na returns NA when no number is present", {
  x <- c("ser", "", "   ", "ET", NA_character_)
  expect_identical(
    keep_number_or_na(x),
    rep(NA_character_, length(x))
  )
})

test_that("keep_number_or_na returns NA when more than one digit run is present", {
  x <- c("15;101", "abc12def34", "1 2", "ID=15 and 16", "007-008")
  expect_identical(
    keep_number_or_na(x),
    rep(NA_character_, length(x))
  )
})

test_that("keep_number_or_na is vectorised and preserves length", {
  x <- c("15", "ser", "15;101", NA_character_, "ID=99")
  out <- keep_number_or_na(x)
  expect_type(out, "character")
  expect_length(out, length(x))
})

test_that("keep_number_or_na errors on non-character input", {
  expect_error(keep_number_or_na(1:3), "`x` must be a character vector")
  expect_error(keep_number_or_na(list("15")), "`x` must be a character vector")
})
