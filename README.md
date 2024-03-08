# ARD Generator
A SAS tool to generate an analysis results dataset from analysis results metadata.

The programs included in this tool are:

## import_adam.sas
Imports XPT files representing ADaM datasets into the `adam` library as SAS datasets.

## import_json_reportingevent.sas
Reads in a JSON file containing ARS Standard-compliant analysis results metadata and transforms it into a series of SAS datasets in the `jsonmd` library. This is an amended version of the program of the same name provided with the Analysis Result Standard at https://github.com/cdisc-org/analysis-results-standard/tree/main/utilities/sas.

## run_analyses.sas
Uses the ARM in the `jsonmd` library to run the analyses defined there, and writes the output to datasets in the `ard` library.