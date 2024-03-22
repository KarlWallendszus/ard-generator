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
libname testdata clear;
libname testdata "&sasbaseard.\macros\test\data" filelockwait=5;
libname testout clear;
libname testout "&sasbaseard.\macros\test\output" filelockwait=5;

* Set date/time macro variables;
%include "&sasbaseard./setprogdt.sas";

* Empty the work library;
%include 'clear_work.sas';

* Copy relevant formats to work library;
proc catalog;
	copy in = testout.formats out = work.formats;
run;
quit;

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

* Test 3.1: Summary by SOC and treatment: N;
data testout.ard_3_1;
	set testdata.ard_template;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth01_CatVar_Summ_ByGrp_1_n, methid=Mth01_CatVar_Summ_ByGrp, 
	analid=An07_09_Soc_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc, 
	analds=testdata.workds_trt_soc, analvar=USUBJID, ard=testout.ard_3_1,
	debugfl=Y);

* Test 3.2: Summary by SOC and treatment: Percentage;
data testout.ard_3_2;
	set testdata.ard_3_2;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth01_CatVar_Summ_ByGrp_2_pct, methid=Mth01_CatVar_Summ_ByGrp, 
	analid=An07_09_Soc_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_06_Soc, 
	analds=testdata.workds_trt_soc, analvar=USUBJID, ard=testout.ard_3_2,
	debugfl=Y);

* Test 4.1: Summary of height by treatment (multiple operations);
data testout.ard_4_1;
	set testdata.ard_template;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_1_n, opseq=1, nop=8, 
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_2_Mean, opseq=2, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_3_SD, opseq=3, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_4_Median, opseq=4, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_5_Q1, opseq=5, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_6_Q3, opseq=6, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_7_Min, opseq=7, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth02_ContVar_Summ_ByGrp_8_Max, opseq=8, nop=8,
	methid=Mth02_ContVar_Summ_ByGrp, 
	analid=An03_06_Height_Summ_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt, 
	analds=testdata.workds_trt_heightbl, analvar=HEIGHTBL, ard=testout.ard_4_1,
	debugfl=N);

* Test 5.1: Comparison of categorical value (age group) by treatment;
data testout.ard_5_1;
	set testdata.ard_template;
run;
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth03_CatVar_Comp_PChiSq_1_chisq, opseq=1, nop=3, 
	methid=Mth03_CatVar_Comp_PChiSq, 
	analid=An03_02_AgeGrp_Comp_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	analds=testdata.workds_trt_agegr, analvar=USUBJID, ard=testout.ard_5_1, 
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth03_CatVar_Comp_PChiSq_2_df, opseq=2, nop=3, 
	methid=Mth03_CatVar_Comp_PChiSq, 
	analid=An03_02_AgeGrp_Comp_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	analds=testdata.workds_trt_agegr, analvar=USUBJID, ard=testout.ard_5_1, 
	debugfl=N);
%run_operation(mdlib=testdata, datalib=testdata,  
	opid=Mth03_CatVar_Comp_PChiSq_3_pval, opseq=3, nop=3, 
	methid=Mth03_CatVar_Comp_PChiSq, 
	analid=An03_02_AgeGrp_Comp_ByTrt, analsetid=AnalysisSet_02_SAF, 
	groupingids=AnlsGrouping_01_Trt|AnlsGrouping_03_AgeGp, 
	analds=testdata.workds_trt_agegr, analvar=USUBJID, ard=testout.ard_5_1, 
	debugfl=N);

* Direct log output back to the log window;
proc printto;
run; 

* Output datasets as JSON;
proc json out = "&sasbaseard.\macros\test\output\test_run_operation_&progdtc_name..json" pretty;
	export testout.ard_1;
	export testout.ard_2_1;
	export testout.ard_2_2;
	export testout.ard_3_1;
	export testout.ard_3_2;
	export testout.ard_4_1;
	export testout.ard_5_1;
run;
