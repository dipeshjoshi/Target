library(forecast)
library(lubridate)

input <- read.csv(file = "oneItem.csv", header = TRUE, stringsAsFactors = FALSE)
input_df <- input[, c("mdse_item_i","mdse_dept_ref_i","week_end_date","sls_unit_q","blackfriday_flag","xmas2_flag","circular_flag","tpc_flag","dollar_off_flag","pct_off_flag")]

input_df$week_end_date <- as.Date(input_df$week_end_date, format('%m/%d/%y'))

ts_obj = ts(input_df$sls_unit_q, start = input_df[1,"week_end_date"], frequency = 52)

xreg_vars <- input_df[, c("blackfriday_flag", "xmas2_flag")]

model <- auto.arima(ts_obj, xreg = xreg_vars, allowdrift = FALSE, approximation = FALSE, stepwise = FALSE)

score_df <- read.csv("oneItem_forward.csv", header = TRUE, stringsAsFactors = FALSE)

score_xreg = score_df[, c("blackfriday_flag", "xmas2_flag")]


r <- forecast(model, xreg = score_xreg, h=52)$mean

plot(r)