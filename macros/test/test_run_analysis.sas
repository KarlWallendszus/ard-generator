/*!
* Tests the run_analysis macro.
* @author Karl Wallendszus
* @created 2023-07_31
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
* options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;

*******************************************************************************;
* Macros
*******************************************************************************;

*******************************************************************************;
* Main code
*******************************************************************************;

* Initialize ARD;
data testout.ard;
	set testdata.ard_template;
run;

* Direct log output to a file;
proc printto log="&logdir.\test_run_analysis_&progdtc_name..log";
run; 

* Test 1: Summary by treatment;
%run_analysis(mdlib=testdata, datalib=testdata, ardlib=testout, 
	analid=An01_05_SAF_Summ_ByTrt, debugfl=Y);

* Test 2: Summary by age group and treament;
%run_analysis(mdlib=testdata, datalib=testdata, ardlib=testout, 
	analid=An03_02_AgeGrp_Summ_ByTrt, debugfl=Y);

* Test 3: Summary by race and treament;
%run_analysis(mdlib=testdata, datalib=testdata, ardlib=testout, 
	analid=An03_05_Race_Summ_ByTrt, debugfl=Y);

* Test 4: Summary by SOC and treament;
%run_analysis(mdlib=testdata, datalib=testdata, ardlib=testout, 
	analid=An07_09_Soc_Summ_ByTrt, debugfl=Y);

* Direct log output back to the log window;
proc printto;
run; 
