#! /usr/bin/env Rscript

args <- commandArgs(TRUE)

# number of weeks for which we need to forecast the sales
forecast_horizon = as.numeric(args[1])
# path to the model directory
model_path = as.character(args[2])


# load necessary libraries and supress warning messages
suppressMessages(library(forecast))
suppressMessages(library(zoo))
suppressMessages(library(lubridate))
suppressMessages(library(caret))
suppressMessages(library(data.table))




load_backup_model <- function(directory, unique_id)
{
         model<-tryCatch(
                {
			compressed_file_name <- mapping[mapping[ ,"V1"] == as.character(unique_id), 2][1]
			system(sprintf("hdfs dfs -copyToLocal %s/%s/%s $(pwd)/", model_path, compressed_file_name))    
                        system(sprintf("tar -xf %s", compressed_file_name))			

                        load(file = paste("backup_",unique_id,'.rda', sep = ''))
			#Deleting extracted files...
                        system("rm *.rda")
                        model_object
                },
                error = function(err){
                        paste("error",sep='')
                }

        )

        return(model)


}



# load time-series model, input is the location of file containing the model
load_model <- function(model_path, unique_id)
{
	model<-tryCatch(
		{
			compressed_file_name <- mapping[mapping[ ,"V1"] == as.character(unique_id), 2][1]		
			system(sprintf("hdfs dfs -copyToLocal %s/%s/%s $(pwd)/", model_path, compressed_file_name))
			
			system(sprintf("tar -xf %s", compressed_file_name))   
        		
			load(file = paste(unique_id,'.rda', sep = ''))
		
			#Deleting extracted files...
			system("rm *.rda")
			model_object
		},
		error = function(err){
			paste("error",sep='')
		}

	)

	return(model)
		

}





load_model_type <- function(directory, unique_id)
{
        type<-tryCatch(
                {
                        model_type <- mapping[mapping[ ,"V1"] == as.character(unique_id), 3]
                        model_type
                },
                error = function(err){
                        paste("error", sep='')
                }
        )

        return(type)
}







forecast_model <- function(item_id, model_type, fit, forecast_horizon, features, promo_features)
{
        #features = features[, colSums(features != 0) > 0]
        if(model_type == "arima"){
                fcst <-tryCatch(
                        {
                                forecast(fit, h = forecast_horizon)$mean
                        },
                        error = function(err){
                                paste("error", sep='')
                        }
                )
        }

	if(model_type == "sarima"){
                fcst <-tryCatch(
                        {
                                forecast(fit, h = forecast_horizon)$mean
                        },
                        error = function(err){
                                paste("error", sep='')
                        }
                )
        }



        if(model_type == "sarimax"){
                fcst <-tryCatch(
                        {	
                                forecast(fit, h = forecast_horizon, xreg=promo_features)$mean
                        },
                        error = function(err){
                                paste("error", sep='')
                        }
                )
        }
        if(model_type == "arimax"){
                fcst <-tryCatch(
                        {
                                forecast(fit, h = forecast_horizon, xreg=features)$mean
                        },
                        error = function(err){
                                paste("error", sep='')
                        }
                )
        }

        if(fcst == "error"){
		fit <- load_backup_model(model_path, item_id)
		fcst <- forecast(fit, h = forecast_horizon)$mean
	
        }


        return(fcst)
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

	
	model_object <- load_model(model_path, item_id)
	model_type <- load_model_type(model_path, item_id)
	
	if(model_object != "error" & model_type !="error")
	{
		train_features <- datain_ordered[(1:forecast_horizon), c(5,6,7,8,9,10), with=FALSE]
		promo_features <- datain_ordered[(1:forecast_horizon), c(7,8,9,10), with=FALSE]
		
		#We have more then one models for given item
		if(length(model_type) > 1)
		{	
			item_forecast <- forecast_model(item_id,model_type[2],model_object,forecast_horizon ,train_features, promo_features)
		}
		else
		{
			item_forecast <- forecast_model(item_id,model_type[1],model_object,forecast_horizon ,train_features, promo_features)
		}	
		for (i in 1:forecast_horizon)
		{
			cat(item_id,"\t",datain$dept_id[1],"\t",as.character(datain_ordered$week_end_date[ i]),"\t",item_forecast[i],"\n")
		}
	}
}



datain <- data.frame(item_id = character(),dept_id = character(),week_end_date = as.Date(character()),sls_unit_q = character(),blackfriday_flag = character(),xmas2_flag = character(),circular=character(),tpc=character(),dollar=character(),pct=character(),stringsAsFactors=FALSE)
datain <- as.data.table(datain)
flag = 0 # flag to skip first iteration
input <- file("stdin","r")

curr_key <- ""


#Read Mapping file 
mapping_file_path <- paste(model_path,'/mapping.csv', sep='')
system(sprintf("hdfs dfs -copyToLocal %s", mapping_file_path))
mapping <- read.table("mapping.csv",  header = FALSE, sep = ',', stringsAsFactor = FALSE)


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
			if(sum(mapping$V1 == curr_key) != 0)
			{	
                        	process_item(datain, curr_key)
			}
                        datain <- NULL
                }

        }else{ flag = 1}

        curr_key <- line_in[1,item_id]
        datain <- rbindlist(list(datain, line_in))
}

if(sum(mapping$V1 == curr_key) != 0 )
{
	process_item(datain, curr_key)
}

close(input)
~            
