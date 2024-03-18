/*!
* Tests the build_work_dataset macro.
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
proc printto log="&logdir.\test_build_work_dataset_&progdtc_name..log";
run; 

* Test 1;
%build_work_dataset(mdlib=testdata, datalib=testdata, analds=adsl, 
	analvar=usubjid, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt);
data testout.workds1;
	set workds;
run;

* Test 2;
%build_work_dataset(mdlib=testdata, datalib=testdata, analds=adsl, 
	analvar=usubjid, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp);
data testout.workds2;
	set workds;
run;

* Test 3;
%build_work_dataset(mdlib=testdata, datalib=testdata, analds=adsl, 
	analvar=usubjid, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_04_Race);
data testout.workds3;
	set workds;
run;

* Test 4;
%build_work_dataset(mdlib=testdata, datalib=testdata, analds=adae, 
	analvar=usubjid, analsetid=AnalysisSet_02_SAF, datasubsetid=Dss01_TEAE, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc);
data testout.workds4;
	set workds;
run;

* Test 5;
%build_work_dataset(mdlib=testdata, datalib=testdata, analds=adsl, 
	analvar=heightbl, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt);
data testout.workds5;
	set workds;
run;

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_build_work_dataset_&progdtc_name..json" pretty;
	export testout.workds1;
	export testout.workds2;
	export testout.workds3;
	export testout.workds4;
	export testout.workds5;
run;

