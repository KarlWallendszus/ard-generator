/*!
* Tests the build_expression macro.
* @author Karl Wallendszus
* @created 2023-03-21
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
proc printto log="&logdir.\test_build_expression_&progdtc_name..log";
run; 

* Create output dataset;
data testout.expressions;
	length id $40 label $200 dsconds $32 expression $200;
	stop;
run;

* Run tests;
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss00_Dummy,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss01_TEAE,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss02_Related_TEAE,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss03_Serious_TEAE,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss04_RelSer_TEAE,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss05_TEAE_Ld2Dth,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss06_Rel_TEAE_Ld2Dth,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss07_TEAE_Ld2DoseMod,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss08_AE_Ld2TrtDsc,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss09_VS_AnRec,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss10_VS_NonBl_AnRec,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss11_TEAE_PlacLow,
	datalib=testdata, dsout=testout.expressions);
%build_expression(dsin=testdata.datasubsets, idvar=id, id=Dss12_TEAE_PlacHigh,
	datalib=testdata, dsout=testout.expressions);

* Direct log output back to the log window;
proc printto;
run; 

* Output results dataset as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_build_expression_&progdtc_name..json" pretty;
	export testout.expressions;
run;
