#1. importing packages.
library(forecast)
library(lubridate)

#2. Reading input data and selecting variables of interest. 
input <- read.csv("oneItem.csv", sep = ',', stringsAsFactors = FALSE, header = TRUE)
input_df <- input[, c("mdse_item_i","mdse_dept_ref_i","week_end_date","sls_unit_q","blackfriday_flag","xmas2_flag","circular_flag","tpc_flag","dollar_off_flag","pct_off_flag")]

input_df$week_end_date <- as.Date(input_df$week_end_date, format = "%m/%d/%y")

#3. Converting data into timeseries object. 
ts_obj <- ts(input_df$sls_unit_q, frequency = 52, start = input_df$week_end_date[1])
#plot.ts(ts_obj)

#4. Training model.
model <- auto.arima(ts_obj)

#5. Forecasting 
r = forecast(model, h=52)$mean

#6. Plotting summaries
plot(r)
plot.ts(model$residuals)
acf(model$residuals)
pacf(model$residuals)
qqnorm(model$residuals)
summary(model)