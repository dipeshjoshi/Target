#In ARIMAX dont give features which contains through out 0. ARIMAX will not converge in that case.

library(forecast)
library(lubridate)

input <- read.csv(file = "oneItem.csv", header = TRUE, stringsAsFactors = FALSE)
input_df <- input[, c('mdse_item_i','mdse_dept_ref_i','week_end_date','sls_unit_q','christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag'	,'halloween_flag'	,'superbowl_flag'	,'blackfriday_flag'	,'cybermonday_flag'	,'goodfriday_flag' ,'xmas1_flag'	,'xmas2_flag', 'circular_flag', 'tpc_flag', 'dollar_off_flag', 'pct_off_flag')]

input_df$week_end_date <- as.Date(input_df$week_end_date, format('%m/%d/%y'))

ts_obj = ts(input_df$sls_unit_q, start = input_df[1,"week_end_date"], frequency = 52)

plot(ts_obj)

holiday_vars <- input_df[, c('christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag', 'xmas1_flag'	,'xmas2_flag', 'pct_off_flag')]

model <- auto.arima(ts_obj, xreg = holiday_vars, allowdrift = FALSE, approximation = FALSE, stepwise = FALSE)

save(model, file = "model.rda")



# Now scoring starts.............
score_df <- read.csv("score.csv", header = TRUE, stringsAsFactors = FALSE)
score_xreg = score_df[, c('christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag' , 'xmas1_flag'	,'xmas2_flag', 'pct_off_flag')]

load(file = "model.rda")

r <- forecast(model, xreg=score_xreg, h=52)$mean

plot(r)