/*!
* Tests the define_analset macro.
* @author Karl Wallendszus
* @created 2023-08-02
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
proc printto log="&logdir.\test_define_analset_&progdtc_name..log";
run; 

* Test 1: ITT population;
* Should yield 254 rows;
%define_analset(mdlib=testdata, datalib=testdata, analsetid=AnalysisSet_01_ITT,
	dsout=testout.analset1);

* Test 2: Safety population;
* Should yield 254 rows;
%define_analset(mdlib=testdata, datalib=testdata, analsetid=AnalysisSet_02_SAF,
	dsout=testout.analset2);

* Test 3: Efficacy population;
* Should yield 234 rows;
%define_analset(mdlib=testdata, datalib=testdata, analsetid=AnalysisSet_03_EFF,
	dsout=testout.analset3);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_define_analset_&progdtc_name..json" pretty;
	export testout.analset1;
	export testout.analset2;
	export testout.analset3;
run;
