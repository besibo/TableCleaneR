test_that("normalize_num_list preserves NA and already-normalized cases", {
  x <- c(NA_character_, "15", "101", "15;101", "15;100;101")
  expect_identical(normalize_num_list(x), x)
})

test_that("normalize_num_list normalizes allowed mixed separators", {
  x <- c("15 ; 101", "15 ET 101", "15-100-101", "15 ; 100 ET 101", "15,101")
  expect_identical(
    normalize_num_list(x, sep = ";"),
    c("15;101", "15;101", "15;100;101", "15;100;101", "15;101")
  )
})

test_that("normalize_num_list returns NA if non-authorized characters are present", {
  x <- c("ser", "ID=15", "15 (101)", "abc15def", "15_ET_101")
  expect_identical(
    normalize_num_list(x),
    rep(NA_character_, length(x))
  )
})

test_that("normalize_num_list returns NA when no digit is found (even if separators are present)", {
  x <- c("", "   ", "ET", " ; - , ET ")
  expect_identical(
    normalize_num_list(x),
    rep(NA_character_, length(x))
  )
})

test_that("normalize_num_list can keep duplicates when unique = FALSE (in non-normalized inputs)", {
  x <- c("15 ET 15 ET 101")
  expect_identical(normalize_num_list(x, unique = FALSE), "15;15;101")
  expect_identical(normalize_num_list(x, unique = TRUE), "15;101")
})

test_that("normalize_num_list validates inputs", {
  expect_error(normalize_num_list(1:3), "must be a character")
  expect_error(normalize_num_list("15", sep = NA_character_), "sep")
  expect_error(normalize_num_list("15", unique = NA), "unique")
})
