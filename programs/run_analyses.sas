/*!
* Runs analyses as defined in the metadata datasets.
* @author Karl Wallendszus
* @created 2023-07-21
*/
*******************************************************************************;

* Set base directory;
%include 'setbase.sas';

* Locate libraries;
%include "&sasbaseard./locate_libs.sas";

* Set working directory;
%let workdir = &sasbaseard.\programs;
%let logdir = &sasbaseard.\log;
x "cd &workdir.";

* Set library references;
*libname metadata "&sasbaseard.\data\metadata" filelockwait=5;
libname jsonmd "&sasbaseard.\data\jsonmd" filelockwait=5;
libname adam "&sasbaseard.\data\adam" filelockwait=5;
libname ard "&sasbaseard.\data\ard" filelockwait=5;

* Set date/time macro variables;
%include "&sasbaseard./setprogdt.sas";

options label dtreset spool;
*options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;

*******************************************************************************;
* Macros
*******************************************************************************;

/**
* Generate an expression string for all given conditions in the input database.
* Assumes the output dataset already exists.
*
* @param dsin		Input dataset.
* @param idvar		Variable in input dataset containing the expression ID.
* @param labelvar	Variable in input dataset containing the expression label.
* @param levelvar	Variable in input dataset containing the clause level.
* @param ordervar	Variable in input dataset containing the clause order.
* @param logopvar	Variable in input dataset containing the logical operator.
* @param dsvar		Variable in input dataset containing the compared dataset.
* @param varvar		Variable in input dataset containing the compared variable.
* @param compvar	Variable in input dataset containing the comparator.
* @param valvar		Variable in input dataset containing the compared value.
* @param datalib	Library containing data to which the expression will be applied.
* @param dsout		Output dataset for condition string.
*/
%macro build_expression_all ( dsin=, idvar=id, labelvar=label, levelvar=level, 
	ordervar=order, logopvar=compndExpression_logicalOperator,
	dsvar=condition_dataset, varvar=condition_variable, 
	compvar=condition_comparator, valvar=condition_value, datalib=, dsout=);

	* Get list of expression IDs from dataset;
	%local ids;
	proc sql;
		select distinct &idvar. into :ids separated by '|'
			from &dsin.
			order by &idvar.;
	quit;

	* Loop through expressions;
	%local iexp id;
	%let iexp = 1;
	%do %while(%scan(&ids., &iexp., '|') ne );
		%let id = %scan(&ids., &iexp., '|');
		%build_expression(dsin=&dsin., idvar=&idvar., labelvar=&labelvar., 
			levelvar=&levelvar., ordervar=&ordervar., logopvar=&logopvar.,
			dsvar=&dsvar., varvar=&varvar., compvar=&compvar., valvar=&valvar, 
			id=&id., datalib=&datalib., dsout=&dsout.);

		%let iexp = %eval(&iexp.+1);
	%end;

%mend build_expression_all;

*******************************************************************************;

/**
* Run all planned analyses.
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param ardlib		Library containing analysis results datasets.
* @param debugfl	Debug flag (Y/N).
*/
%macro run_planned_analyses ( mdlib=, datalib=, ardlib=, debugfl=N );

	* Get list of planned analyses;
	%local analids;
	proc sql;
		select distinct analysisid into :analids separated by '|'
			from &mdlib..listofplannedanalyses
			where analysisid ^= ''
			order by 1;
	quit;

	* Loop through analyses;
	%local ianal analid;
	%let ianal = 1;
	%do %while(%scan(&analids., &ianal., '|') ne );
		%let analid = %scan(&analids., &ianal., '|');

		* Run this analysis;
		%run_analysis(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib.,
			analid=&analid., debugfl=&debugfl.);

		%let ianal = %eval(&ianal.+1);
	%end;

%mend run_planned_analyses;

*******************************************************************************;
* Main code
*******************************************************************************;

* Create dataset for expressions in SAS syntax for conditions;
data jsonmd.expressions;
	length id $40 label $200 dsconds $32 expression $200;
	stop;
run;

* Derive expressions in SAS syntax for conditions;
%build_expression_all(dsin=jsonmd.analysissets, datalib=adam, 
	dsout=jsonmd.expressions);
%build_expression_all(dsin=jsonmd.datasubsets, datalib=adam, 
	dsout=jsonmd.expressions);
%build_expression_all(dsin=jsonmd.analysisgroupings, idvar=group_id, 
	labelvar=group_label, levelvar=group_level, 
	ordervar=order, logopvar=group_logicalOperator,
	dsvar=group_condition_dataset, varvar=group_condition_variable, 
	compvar=group_condition_comparator, valvar=condition_value, 
	datalib=adam, dsout=jsonmd.expressions);

* Initialize ARD;
data ard.ard;
	set ard.ard_template;
run;

* Direct log output to a file;
proc printto log="&logdir.\run_analyses_&progdtc_name..log";
run; 

* Run analyses;
%run_planned_analyses(mdlib=jsonmd, datalib=adam, ardlib=ard);
/*
%run_analysis(mdlib=jsonmd, datalib=adam, ardlib=ard, 
	analid=An01_05_SAF_Summ_ByTrt, debugfl=Y);
%run_analysis(mdlib=jsonmd, datalib=adam, ardlib=ard, 
	analid=An03_02_AgeGrp_Summ_ByTrt, debugfl=Y);
%run_analysis(mdlib=jsonmd, datalib=adam, ardlib=ard, 
	analid=An03_05_Race_Summ_ByTrt, debugfl=Y);
%run_analysis(mdlib=jsonmd, datalib=adam, ardlib=ard, 
	analid=An07_09_Soc_Summ_ByTrt, debugfl=Y);
*/

* Sort the analysis results dataset;
proc sort data = ard.ard;
	by analysisid methodid operationid resultgroup1_groupid resultgroup2_groupid 
		resultgroup3_groupid;
run;

* Direct log output back to the log window;
proc printto;
run; 
