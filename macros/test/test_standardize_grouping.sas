/*!
* Tests the standardize_grouping macro.
* @author Karl Wallendszus
* @created 2023-07_21
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
proc printto log="&logdir.\test_standardize_grouping_&progdtc_name..log";
run; 

* Test 1: Treatment;
%standardize_grouping(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, datalib=testdata, 
	dsout=testout.stdgrping1, dsvals=groupvals1, 
	ids=AnlsGrouping_01_Trt);
proc tabulate data = testout.stdgrping1;
	class AnlsGrouping_01_Trt;
	table AnlsGrouping_01_Trt all, n;
run;

* Test 2: Treatment & sex;
%standardize_grouping(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, datalib=testdata, 
	dsout=testout.stdgrping2, dsvals=groupvals2, 
	ids=AnlsGrouping_02_Sex|AnlsGrouping_01_Trt);
proc tabulate data = testout.stdgrping2;
	class AnlsGrouping_02_Sex AnlsGrouping_01_Trt;
	table AnlsGrouping_02_Sex all, ( AnlsGrouping_01_Trt all ) * n;
run;

* Test 3: Treatment & age group;
%standardize_grouping(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, datalib=testdata, 
	dsout=testout.stdgrping3, dsvals=groupvals3, 
	ids=AnlsGrouping_03_AgeGp|AnlsGrouping_01_Trt);
proc tabulate data = testout.stdgrping3;
	class AnlsGrouping_03_AgeGp AnlsGrouping_01_Trt;
	table AnlsGrouping_03_AgeGp all, ( AnlsGrouping_01_Trt all ) * n;
run;

* Test 4: Treatment & SOC;
%standardize_grouping(dsgrp=testdata.analysisgroupings, 
	dsexpr=testdata.expressions, datalib=testdata, dsdd=adae,
	dsout=testout.stdgrping4, dsvals=groupvals4, 
	ids=AnlsGrouping_06_Soc|AnlsGrouping_01_Trt);
proc tabulate data = testout.stdgrping4;
	class AnlsGrouping_06_Soc AnlsGrouping_01_Trt;
	table AnlsGrouping_06_Soc all, ( AnlsGrouping_01_Trt all ) * n;
run;

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_standardize_grouping_&progdtc_name..json" pretty;
	export testout.stdgrping1;
	export testout.stdgrping2;
	export testout.stdgrping3;
	export testout.stdgrping4;
proc json out = "&sasbaseard.\macros\test\output\test_groupvals_&progdtc_name..json" pretty;
	export groupvals1;
	export groupvals2;
	export groupvals3;
	export groupvals4;
run;
