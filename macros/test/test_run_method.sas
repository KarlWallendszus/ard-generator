/*!
* Tests the run_method macro.
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
proc printto log="&logdir.\test_run_method_&progdtc_name..log";
run; 

* Test 1: Summary by treatment;
%run_method(mdlib=testdata, datalib=testdata, ardlib=testout, 
	methid=Mth01_CatVar_Count_ByGrp, analid=An01_05_SAF_Summ_ByTrt, 
	analsetid=AnalysisSet_02_SAF, analds=ADSL, analvar=USUBJID, 
	groupingids=AnlsGrouping_01_Trt,
	debugfl=N);

* Test 2: Summary by age group and treatment;
%run_method(mdlib=testdata, datalib=testdata, ardlib=testout, 
	methid=Mth01_CatVar_Summ_ByGrp, analid=An03_02_AgeGrp_Summ_ByTrt, 
	analsetid=AnalysisSet_02_SAF, analds=ADSL, analvar=USUBJID, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, debugfl=N);

* Test 3: Summary by race and treatment;
%run_method(mdlib=testdata, datalib=testdata, ardlib=testout, 
	methid=Mth01_CatVar_Summ_ByGrp, analid=An03_05_Race_Summ_ByTrt, 
	analsetid=AnalysisSet_02_SAF, analds=ADSL, analvar=USUBJID, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_04_Race, debugfl=N);

* Test 4: Summary by SOC and treatment;
%run_method(mdlib=testdata, datalib=testdata, ardlib=testout, 
	methid=Mth01_CatVar_Summ_ByGrp, analid=An07_09_Soc_Summ_ByTrt, 
	analsetid=AnalysisSet_02_SAF, datasubsetid=Dss01_TEAE, analds=ADAE, 
	analvar=USUBJID, groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc, 
	debugfl=Y);

* Direct log output back to the log window;
proc printto;
run; 
