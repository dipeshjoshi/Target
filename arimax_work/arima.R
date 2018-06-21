library(forecast)
library(lubridate)

# Reading data and selecting features of interest. 
in_df <- read.csv("dept8.csv", sep = ',', header = TRUE, stringsAsFactors = FALSE)

input <- in_df[,c('mdse_item_i','mdse_dept_ref_i','week_end_date','sls_unit_q','christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag'	,'halloween_flag'	,'superbowl_flag'	,'blackfriday_flag'	,'cybermonday_flag'	,'goodfriday_flag' ,'xmas1_flag'	,'xmas2_flag')]
out_file <- file('output.txt')


process_item <- function(curr_item_df){
  res <- tryCatch(
    {
      item_id <- curr_item_df[1,1]
      curr_item_df$week_end_date <- as.Date(curr_item_df$week_end_date, format('%m/%d/%y'))
      ts_obj <- ts(curr_item_df$sls_unit_q, start = curr_item_df[1,"week_end_date"], frequency = 52)
      xreg_vars <- curr_item_df[ ,c('christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag', 'halloween_flag'	,'superbowl_flag'	,'cybermonday_flag', 'goodfriday_flag', 'xmas1_flag'	,'xmas2_flag')]
      model <- auto.arima(ts_obj, xreg = xreg_vars, allowdrift = FALSE, approximation = FALSE, stepwise = FALSE)
      save(model, file = paste(item_id,'.rda', sep = ''))
    },
    error = function(err){
      paste("error", sep='')
    }
  )
  
}


#Create itme wise data.
curr_item <- input[1,1]
curr_item_df <- data.frame()
for(index in 1:nrow(input)){
  if(curr_item != input[index,1]){
    process_item(curr_item_df)
    curr_item <<- input[index,1]
    curr_item_df <<- data.frame()
  }
  if(nrow(curr_item_df) == 0){
    #1st row of new item. 
    curr_item_df <<- input[index,]
    colnames(curr_item_df) <- c('mdse_item_i','mdse_dept_ref_i','week_end_date','sls_unit_q','christmas_flag', 'easter_flag', 'thanksgiving_flag', 'newyearsday_flag', 'fathersday_flag' ,'mothersday_flag'	,'julyfourth_flag'	,'valentines_flag'	,'halloween_flag'	,'superbowl_flag'	,'blackfriday_flag'	,'cybermonday_flag'	,'goodfriday_flag' ,'xmas1_flag'	,'xmas2_flag')
  }
  else{
    curr_item_df <- rbind(curr_item_df, input[index,])
  }
}





