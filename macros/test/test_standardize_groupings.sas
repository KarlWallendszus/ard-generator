/*!
* Tests the standardize_groupings macro.
* @author Karl Wallendszus
* @created 2023-08-29
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
proc printto log="&logdir.\test_standardize_groupings_&progdtc_name..log";
run; 

* Test 1: Treatment;
%standardize_groupings(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, dsin=testdata.groupingtest1, 
	dsout=testout.groupingtest1, fmtlib=testout, debugfl=Y,
	ids=AnlsGrouping_01_Trt);

* Test 2: Treatment & sex;
%standardize_groupings(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, dsin=testdata.groupingtest2, 
	dsout=testout.groupingtest2, fmtlib=testout, 
	ids=AnlsGrouping_01_Trt|AnlsGrouping_02_Sex);

* Test 3: Treatment & age group;
%standardize_groupings(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, dsin=testdata.groupingtest3, 
	dsout=testout.groupingtest3, fmtlib=testout, 
	ids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp);

* Test 4: Treatment & SOC;
%standardize_groupings(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, dsin=testdata.groupingtest4, 
	dsout=testout.groupingtest4, fmtlib=testout, 
	ids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_standardize_groupings_&progdtc_name..json" pretty;
	export testout.groupingtest1;
	export testout.groupingtest2;
	export testout.groupingtest3;
	export testout.groupingtest4;
run;
