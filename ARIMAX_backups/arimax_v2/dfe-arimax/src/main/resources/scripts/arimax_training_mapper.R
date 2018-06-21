#! /usr/bin/env Rscript
input <- file("stdin", "r")

while(length(line <- readLines(input,n=1,warn=FALSE)) > 0) {

        if(nchar(line) == 0) break
	
        valid_data <- unlist(strsplit(line, "\x01"))
	
	cat(valid_data[1],"\t",valid_data[3],"\t",valid_data[5],"\t",valid_data[9],"\t",valid_data[34],"\t",valid_data[56],"\t",valid_data[11],"\t",valid_data[15],"\t", valid_data[17],"\t",valid_data[19], "\n",sep='')		

}
close(input)
