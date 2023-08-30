/*!
* Tests the outline_ard macro.
* @author Karl Wallendszus
* @created 2023-08-30
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
libname testdata "&sasbaseard.\macros\test\data" filelockwait=5;
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
proc printto log="&logdir.\test_outline_ard_&progdtc_name..log";
run; 

* Test 1: 1 operation, 1 grouping;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An01_05_SAF_Summ_ByTrt, 
	groupingids=AnlsGrouping_01_Trt, 
	dsin=testdata.groupingtest1, dsout=testout.outline_ard1, debugfl=Y);

* Test 2: 2 operations, 2 groupings;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_03_Sex_Summ_ByTrt, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_02_Sex, 
	dsin=testdata.groupingtest2, dsout=testout.outline_ard2, debugfl=Y);

* Test 3: 2 operations, 2 groupings;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_02_AgeGrp_Summ_ByTrt, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	dsin=testdata.groupingtest3, dsout=testout.outline_ard3, debugfl=Y);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_outline_ard_&progdtc_name..json" pretty;
	export testout.workds1;
	export testout.workds2;
run;

