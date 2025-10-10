#!/usr/bin/env Rscript

initial.options = commandArgs(trailingOnly=FALSE)
script.basename <- basename(sub("--file=", "", initial.options[grep("--file=", initial.options)]))
script.dirname <- dirname(sub("--file=", "", initial.options[grep("--file=", initial.options)]))

args = commandArgs(trailingOnly=TRUE)

if (length(args) < 4 || length(args) >= 6) {
  stop(paste("Usage:", script.basename, "all.log geolocations.csv report.md OUT_DIR [tool_tags.tsv]",
             "\nNote: You can obtain `all.log` and `geolocations.csv`` by executing ./process_log_file.sh on the",
             "concatenated raw log file."),
        call.=FALSE)
}

output_dir=args[4]

if (!(output_dir[1] == "/")) # relative path
{
    output_dir = paste(getwd(), output_dir, sep = "/")
}

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

output_filename=paste(output_dir, "report.html", sep = "/")

if (file.exists(output_filename))
{
    paste("[Warning] Overwriting output file ", output_filename, ".")
}

message("=============================================================================")
message("                                 START")
message("=============================================================================")

message("")

log_file_name=paste(getwd(), args[1], sep="/");
geo_loc_file_name=paste(getwd(), args[2], sep="/");
report_file_name=paste(getwd(), args[3], sep="/");

if (length(args) > 4) {
    tooltag_file_name=paste(getwd(), args[5], sep="/");
    message(paste("Found tooltags in ", tooltag_file_name))
}

message("")
message(paste("--- Source file ", paste(script.dirname, '/global.R', sep='')))
source(paste(script.dirname, '/global.R', sep=''));

message("")
message(paste("--- Render file ", args[3]))
rmarkdown::render(report_file_name, output_file=output_filename, output_format="html_document")
