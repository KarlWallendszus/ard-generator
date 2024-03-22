/*!
* Tests the append_addcols macro.
* @author Karl Wallendszus
* @created 2023-09-06
*/
*******************************************************************************;

* Set base directory;
%include 'setbase.sas';

* Locate libraries;
%include "&sasbaseard./locate_libs.sas";

* Set working directory;
%let workdir = &sasbaseard.\macros\test;
%let logdir = &sasbaseard.\macros\test\log;
x "cd &workdir.";

* Set library references;
libname testdata clear;
libname testdata "&sasbaseard.\macros\test\data" filelockwait=5;
libname testout clear;
libname testout "&sasbaseard.\macros\test\output" filelockwait=5;

* Set date/time macro variables;
%include "&sasbaseard./setprogdt.sas";

options label dtreset spool;
*options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;

*******************************************************************************;
* Macros
*******************************************************************************;

*******************************************************************************;
* Main code
*******************************************************************************;

* Direct log output to a file;
proc printto log="&logdir.\test_append_addcols_&progdtc_name..log";
run; 

* Same columns;
data testout.append_addcols_1;
	set testdata.cars_base;
run;
%append_addcols(dsbase=testout.append_addcols_1, dsnew=testdata.cars_acura, 
	debugfl=Y);

* More columns in new dataset;
data testout.append_addcols_2;
	set testdata.cars_acura;
run;
%append_addcols(dsbase=testout.append_addcols_2, dsnew=testdata.cars_audi, 
	debugfl=Y);

* Both datasets have some columns unique to them;
data testout.append_addcols_3;
	set testdata.cars_audi;
run;
%append_addcols(dsbase=testout.append_addcols_3, dsnew=testdata.cars_bmw);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_append_addcols_&progdtc_name..json" pretty;
	export testout.append_addcols_1;
	export testout.append_addcols_2;
	export testout.append_addcols_3;
run;
