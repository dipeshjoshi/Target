library(forecast)
library(lubridate)

input_df <- read.csv(file = "dept8_forward.csv", stringsAsFactors = FALSE)
input <- input_df[ , c('mdse_item_i','mdse_dept_ref_i','week_end_date','christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag'	,'halloween_flag'	,'superbowl_flag'	,'blackfriday_flag'	,'cybermonday_flag'	,'goodfriday_flag' ,'xmas1_flag'	,'xmas2_flag')]


score_item <- function(curr_item_df){
  item_id = curr_item_df[1,1]
  xreg_vars <- curr_item_df[ ,c('christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag', 'halloween_flag'	,'superbowl_flag'	,'cybermonday_flag', 'goodfriday_flag', 'xmas1_flag'	,'xmas2_flag')]
  model <- load(paste(item_id,'.rda', sep = ''))
  pred <- forecast(model, xreg = xreg_vars, h=52)$mean
  print(pred)
}



curr_item = input[1,1]
curr_item_df = data.frame()

for(index in 1:nrow(input)){
  if(input[index,1] != curr_item){
    score_item(curr_item_df)
    curr_item_df = data.frame()
    curr_item = input[index,1]
  }
  if(nrow(curr_item_df) == 0){
    curr_item_df <- input[index, ]
    colnames(curr_item_df) <- c('mdse_item_i','mdse_dept_ref_i','week_end_date','christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag'	,'halloween_flag'	,'superbowl_flag'	,'blackfriday_flag'	,'cybermonday_flag'	,'goodfriday_flag' ,'xmas1_flag'	,'xmas2_flag')
  }
  else{
    curr_item_df <- rbind(curr_item_df, input[index, ])
  }
}