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

* Direct log output to a file;
proc printto log="&logdir.\test_run_method_&progdtc_name..log";
run; 

* Test 1.1: Categorical variable count by group;
%run_operation(mdlib=testdata, datalib=testdata, ardlib=testout, 
	opid=Mth01_CatVar_Count_ByGrp_1_n, methid=Mth01_CatVar_Count_ByGrp, 
	analid=An01_05_SAF_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt, analvar=USUBJID, debugfl=Y);

* Test 2.1: Summary by age group and treatment;

* Test 2.2: Summary by race and treatment;

* Test 2.3: Summary by SOC and treatment;

* Direct log output back to the log window;
proc printto;
run; 
