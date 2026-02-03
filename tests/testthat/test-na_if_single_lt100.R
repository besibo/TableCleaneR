test_that("na_if_single_lt100 replaces single integers < 100 with NA", {
  x <- c("0", "1", "15", "99", "015", "000", "00099")
  expect_identical(
    na_if_single_lt100(x),
    rep(NA_character_, length(x))
  )
})

test_that("na_if_single_lt100 keeps single integers >= 100 unchanged", {
  x <- c("100", "101", "999", "0100", "000101")
  expect_identical(
    na_if_single_lt100(x),
    x
  )
})

test_that("na_if_single_lt100 leaves non-digit strings and multi-number strings unchanged", {
  x <- c(NA_character_, "ser", "15;101", "ID=15", "15 101", "99a", "a99")
  expect_identical(
    na_if_single_lt100(x),
    x
  )
})

test_that("na_if_single_lt100 is vectorised and preserves length/type", {
  x <- c("15", "100", NA_character_, "ser", "15;101")
  out <- na_if_single_lt100(x)
  expect_type(out, "character")
  expect_length(out, length(x))
})

test_that("na_if_single_lt100 returns input unchanged if there are no digit-only elements", {
  x <- c(NA_character_, "ser", "15;101", "ID=15")
  expect_identical(na_if_single_lt100(x), x)
})

test_that("na_if_single_lt100 errors on non-character input", {
  expect_error(na_if_single_lt100(1:3), "`x` must be a character vector")
  expect_error(na_if_single_lt100(list("15")), "`x` must be a character vector")
})
