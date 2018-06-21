#! /usr/bin/env Rscript

args <- commandArgs(TRUE)

# number of weeks for which we need to forecast the sales
#number_of_rolling_windows = as.numeric(args[1])
model_path = as.character(args[1])
suppressMessages(library(forecast))
suppressMessages(library(lubridate))
suppressMessages(library(data.table))
mapping <- data.frame(item_id=character(), comp_file_name=character(), model_type=character(), stringsAsFactors=FALSE)


train_simple_model <- function(train_ts)
{

	fit <- tryCatch(
                {
                        fitted_model <-auto.arima(train_ts,xreg=NULL, allowdrift = FALSE, approximation = FALSE, stepwise=FALSE)
                        fitted_model
                },
                error = function(err){
                        return("error")
                }
        )

        
        return (list(fit,"arima"))

}

train_model <- function(train_ts,  train_features, promo_features)
{

	cat(length(train_ts),"\t")

	fit1 <- tryCatch(
		{
			fitted_model <- auto.arima(train_ts,D=1,xreg=promo_features, allowdrift = FALSE, approximation = FALSE, stepwise=FALSE)
			fitted_model
		},
		error = function(err){
			return("error")
		}
	)

	if (fit1 != "error"){
		cat("SARIMAX\n")
                return (list(fit1,"sarimax"))
        }
	fit2 <- tryCatch(
                {
                        fitted_model <- auto.arima(train_ts,D=1, allowdrift = FALSE, approximation = FALSE, stepwise=FALSE)
                        fitted_model
                },
                error = function(err){
                        return("error")
                }
        )

        if (fit2 != "error"){
                cat("SARIMA\n")
                return (list(fit2,"sarima"))
        }
	
	fit3 <- tryCatch(
		{
			fitted_model <-auto.arima(train_ts,xreg=train_features, allowdrift = FALSE, approximation = FALSE, stepwise=FALSE)
                        fitted_model
           
		},
		error = function(err){
			return("error")
		}
	)

	if (fit3 != "error"){
		cat("ARIMAX\n")	
                return (list(fit3,"arimax"))
         }

	fit4 <- tryCatch(
                {
                        fitted_model <-auto.arima(train_ts,xreg=NULL, allowdrift = FALSE, approximation = FALSE, stepwise=FALSE)
                        fitted_model
                },      
                error = function(err){
			return("error")
                }
        )
	cat("ARIMA\n")
        return (list(fit4,"arima"))

}



process_item <- function(datain, curr_key)
{
	item_id <- as.numeric(curr_key)
	colnames(datain) <- c('item_id','dept_id','week_end_date','sls_unit_q', 'blackfriday_flag','xmas2_flag','circular','tpc','dollar','pct')
	datain$item_id <- as.character(datain$item_id)
	datain$dept_id <- as.character(datain$dept_id)
	datain$week_end_date <- as.Date(datain$week_end_date, format="%Y-%m-%d")
	datain$sls_unit_q <- as.numeric(datain$sls_unit_q)
	datain$blackfriday_flag <-as.numeric(datain$blackfriday_flag)
	datain$xmas2_flag <- as.numeric(datain$xmas2_flag)
	datain$circular <- as.numeric(datain$circular)
	datain$tpc <- as.numeric(datain$tpc)
	datain$dollar <- as.numeric(datain$dollar)
	datain$pct <- as.numeric(datain$pct)
	datain_ordered <- datain[order(datain$item_id,datain$week_end_date), ]


			

	train_series<-tryCatch(
		{
			train_ts <- ts(datain_ordered$sls_unit_q, frequency = 52, start = decimal_date(ymd(datain_ordered$week_end_date[1])))
			train_ts
		},
		error = function(err){
			paste("error",sep='')

		}
	)

	if(train_series != "error"){
		
		no_item_flag <<- FALSE
				
		train_end_index <- length(train_series)
		train_features <- datain_ordered[(1:train_end_index), c(5,6,7,8,9,10), with=FALSE]
			
		promo_features <- datain_ordered[(1:train_end_index), c(7,8,9,10), with=FALSE]
		item_model <- train_model(train_series,  train_features,promo_features)			
		if(item_model[[2]] != "arima"){
			cat("backup ","\t",item_id,"\n")
			backup_model <- train_simple_model(train_series)
			save_backup_model(model_path, item_id, backup_model[[1]], backup_model[[2]])
		}
		
		if(item_model[[1]] != "error"){

			save_model(model_path, item_id, item_model[[1]], item_model[[2]])
			#save_model_type(model_path, item_id, item_model[[2]])

		}else{cat(item_id,"\t", "model error","\n")}
	}else{cat(item_id,"\t", "series error","\n")}	

}


save_model_type <- function(directory,unique_id, model_type)
{
        save(model_type, file = paste('mt_',unique_id,'.rda', sep = ''))
        system(sprintf("hdfs dfs -rm -f %s/%s/mt_%s.rda", directory, unique_id))
        system(sprintf("hdfs dfs -put mt_%s.rda %s/%s/", unique_id, directory))

}

save_backup_model <- function(directory,unique_id, model_object, model_type)
{
	save(model_object, file = paste('backup_',unique_id,'.rda', sep = ''))
        mapping[nrow(mapping)+1, ] <<- c(as.integer(unique_id), as.character(compressed_file), as.character(model_type))

	if(comp_flag == 0){
		print("BACKUP MODEL 1st ITEM")
                system(sprintf("tar -cvf %s backup_%s.rda", compressed_file, unique_id))
                comp_flag <<- 1
        }
        else {
		print("BACKUP MODEL NOT A 1st ITEM")
                system(sprintf("tar -uvf %s backup_%s.rda", compressed_file, unique_id))
        }
}



save_model <- function(directory,unique_id, model_object, model_type)
{
        save(model_object, file = paste(unique_id,'.rda', sep = ''))
	mapping[nrow(mapping)+1, ] <<- c(as.integer(unique_id), as.character(compressed_file), as.character(model_type))
	
	if(comp_flag == 0){
		system(sprintf("tar -cvf %s %s.rda", compressed_file, unique_id))
		comp_flag <<- 1
	}
	else{
		system(sprintf("tar -uvf %s %s.rda", compressed_file, unique_id))
	}
}


create_directory <- function(directory)
{
        system(sprintf("hdfs dfs -mkdir -p %s/%s/", directory))
}


create_directory(model_path)
datain <- data.frame(item_id = character(),dept_id = character(),week_end_date = as.Date(character()),sls_unit_q = character(),blackfriday_flag = character(),xmas2_flag = character(),circular=character(),tpc=character(),dollar=character(),pct=character(),stringsAsFactors=FALSE)
datain <- as.data.table(datain)
flag = 0 # flag to skip first iteration
input <- file("stdin","r")

curr_key <- ""
comp_flag <- 0

#Generating random string.
file_name <- round(runif(1, 1000000000, 9999999999), 0)
compressed_file <- paste(file_name, '.tar', sep="")
mapping_file <- paste(file_name, ".csv", sep="")
no_item_flag <- TRUE

# read one line at a time while we have content
while(length(line <- readLines(input, n=1, warn=FALSE)) > 0){ 
	if(nchar(line) == 0) break  # if at any point we get a null row then exit the loop
	# store the current line into a variable
	line_in <- data.frame(t(unlist(strsplit(line, "\t"))),stringsAsFactors=FALSE)
	line_in <- as.data.table(line_in)
	colnames(line_in) <- c('item_id','dept_id','week_end_date','sls_unit_q', 'blackfriday_flag','xmas2_flag','circular','tpc','dollar','pct')
	line_in$week_end_date <- as.Date(line_in$week_end_date, format="%Y-%m-%d")
	# skip first iteration to obtain the current key
	if(flag != 0){
		
		if(line_in[1,item_id] != curr_key){
			process_item(datain, curr_key)
			datain <- NULL
		}
		
	}else{ flag = 1}

	curr_key <- line_in[1,item_id]
	datain <- rbindlist(list(datain, line_in))
}

# handle last item
process_item(datain, curr_key)

if(!no_item_flag){
	system(sprintf("hdfs dfs -put %s %s/%s/", compressed_file, model_path))
	write.table(mapping, file = mapping_file, row.names = FALSE, col.names = FALSE, sep = ',')
	#system(sprintf("hdfs dfs -put %s %s", mapping_file, output_path))
	system(sprintf("hdfs dfs -put %s %s/%s/", mapping_file, model_path))
}

close(input)
