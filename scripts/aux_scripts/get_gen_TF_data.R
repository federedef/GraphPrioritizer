
#!/usr/bin/env Rscript
library(OmnipathR)
library(optparse)

option_list <- list(
        make_option(c("-O", "--output_path"), type="character", default="./htridb_data",
                help="Path with name of the output file")
        )

opt <- parse_args(OptionParser(option_list=option_list))

print("Downloading FT-gen human data")
htridb_download <- htridb_download()
print("Selection Gen-TF data")
Gen_FT <- unique(cbind(htridb_download$SYMBOL_TG ,htridb_download$SYMBOL_TF))
write.table(Gen_FT,opt$output_path,sep="\t",col.names=F,row.names=F,quote=F)
