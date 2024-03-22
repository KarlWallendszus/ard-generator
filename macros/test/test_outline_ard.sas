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

* Empty the work library;
%include 'clear_work.sas';

* Direct log output to a file;
proc printto log="&logdir.\test_outline_ard_&progdtc_name..log";
run; 

* Test 1: 1 operation, 1 grouping;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An01_05_SAF_Summ_ByTrt, 
	opid=Mth01_CatVar_Count_ByGrp_1_n, groupingids=AnlsGrouping_01_Trt, 
	dsin=testdata.groupingtest1, dsout=testout.outline_ard1, debugfl=Y);

* Test 2: 2 operations, 2 groupings;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_03_Sex_Summ_ByTrt, 
	opid=Mth01_CatVar_Summ_ByGrp_1_n, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_02_Sex, 
	dsin=testdata.groupingtest2, dsout=testout.outline_ard2_1, debugfl=Y);
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_03_Sex_Summ_ByTrt, 
	opid=Mth01_CatVar_Summ_ByGrp_2_pct, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_02_Sex, 
	dsin=testdata.groupingtest2, dsout=testout.outline_ard2_2, debugfl=Y);

* Test 3: 2 operations, 2 groupings;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_02_AgeGrp_Summ_ByTrt,
	opid=Mth01_CatVar_Summ_ByGrp_1_n, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	dsin=testdata.groupingtest3, dsout=testout.outline_ard3_1, debugfl=Y);
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_02_AgeGrp_Summ_ByTrt,
	opid=Mth01_CatVar_Summ_ByGrp_2_pct, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	dsin=testdata.groupingtest3, dsout=testout.outline_ard3_2, debugfl=Y);

* Test 4: 2 operations, 2 groupings, one of them data-driven;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An07_09_Soc_Summ_ByTrt,
	opid=Mth01_CatVar_Summ_ByGrp_1_n, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc, 
	dsin=testdata.workds_trt_soc, dsout=testout.outline_ard4_1);
%outline_ard(ardlib=testout, mdlib=testdata, analid=An07_09_Soc_Summ_ByTrt,
	opid=Mth01_CatVar_Summ_ByGrp_2_pct, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc, 
	dsin=testdata.workds_trt_soc, dsout=testout.outline_ard4_2);

* Test 5: 1 operations, 2 groupings with results noy by group;
%outline_ard(ardlib=testout, mdlib=testdata, analid=An03_02_AgeGrp_Comp_ByTrt,
	opid=Mth03_CatVar_Comp_PChiSq_1_pval, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	dsin=testdata.groupingtest3, dsout=testout.outline_ard5_1);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_outline_ard_&progdtc_name..json" pretty;
	export testout.outline_ard1;
	export testout.outline_ard2_1;
	export testout.outline_ard2_2;
	export testout.outline_ard3_1;
	export testout.outline_ard3_2;
	export testout.outline_ard4_1;
	export testout.outline_ard4_2;
	export testout.outline_ard5_1;
run;

