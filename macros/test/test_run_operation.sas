/*!
* Tests the run_operation macro.
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

* Copy relevant formats to work library;
proc catalog;
	copy in = testout.formats out = work.formats;
run;
quit;

* Direct log output to a file;
proc printto log="&logdir.\test_run_operation_&progdtc_name..log";
run; 

* Test 1: Categorical variable count by group;
data testout.ard_1;
	set testdata.ard_template;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth01_CatVar_Count_ByGrp_1_n, methid=Mth01_CatVar_Count_ByGrp, 
	analid=An01_05_SAF_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt, analvar=USUBJID, ard=testout.ard_1, 
	debugfl=Y);

* Test 2.1: Summary by age group and treatment: N;
data testout.ard_2_1;
	set testdata.ard_template;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth01_CatVar_Summ_ByGrp_1_n, methid=Mth01_CatVar_Summ_ByGrp, 
	analid=An03_02_AgeGrp_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	analds=testdata.workds_trt_agegr, analvar=USUBJID, ard=testout.ard_2_1, 
	debugfl=Y);

* Test 2.2: Summary by age group and treatment: Percentage;
data testout.ard_2_2;
	set testdata.ard_2_2;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth01_CatVar_Summ_ByGrp_2_pct, methid=Mth01_CatVar_Summ_ByGrp, 
	analid=An03_02_AgeGrp_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	analds=testdata.workds_trt_agegr, analvar=USUBJID, ard=testout.ard_2_2);

* Test 3: Summary by SOC and treatment;

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_run_operation_&progdtc_name..json" pretty;
	export testout.ard_1;
	export testout.ard_2_1;
	export testout.ard_2_2;
run;
