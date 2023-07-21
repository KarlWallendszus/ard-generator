/*!
* Runs analyses as defined in the metadata datasets.
* @author Karl Wallendszus
* @created 2023-03-21
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
* Determines whether a given variable is charaacter or numeric and returns the
* answer in the macro variable var_type	('C' = character, 'N' = numeric).
*
* @param	dsin		Name of input dataset.
* @param	varname		Name of variable to check.
*/
%macro get_var_type ( dsin=, varname= );

	* Initialisation;
	%global var_type;
	%local rc dsid var_num;
	%let var_type = %str();

	* Open the dataset;
	%let dsid = %sysfunc(open(&dsin.));

	* Get variable number within dataset;
	%let var_num = %sysfunc(varnum(&dsid., &varname.));

	* Get variable type;
	%let var_type = %sysfunc(vartype(&dsid., &var_num.));

	* Close the dataset;
	%let rc = %sysfunc(close(&dsid.));

%mend get_var_type;

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
* Create a work dataset to define the analysis set population;
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param analsetid	Analysis set ID.
*/
%macro define_analset ( mdlib=, datalib=, analsetid= );

	* Get analysis set details;
	%local analsetlabel dscond condvar condstr;
	proc sql;
		select a.label, a.condition_dataset, a.condition_variable, 
				e.expression
				into :analsetlabel, :dscond, :condvar, :condstr
			from &mdlib..analysissets a join &mdlib..expressions e
				on a.id = e.id
			where a.id = "&analsetid.";
	quit;

	* Create a dataset to define the analysis set population;
	data analset ( keep = usubjid &condvar. );
		set &datalib..&dscond. ( where = (&condstr.) );
	run;

%mend define_analset;

*******************************************************************************;

/**
* Creates a work dataset containing a list of datasets and variables required 
* for the specified analysis groupings.
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param groupingid1	Analysis grouping ID 1.
* @param groupingid2	Analysis grouping ID 2.
* @param groupingid3	Analysis grouping ID 3.
*/
%macro get_groupingvars ( mdlib=, groupingid1=, groupingid2=, groupingid3= );

	* Create dataset containing relevant grouping details;
	proc sql;
		create table groupingvars
			as select distinct group_condition_dataset, group_condition_variable
				from &mdlib..analysisgroupingsx
			where id in ("&groupingid1.", "&groupingid2.", "&groupingid3.");
	quit;

%mend get_groupingvars;

*******************************************************************************;

/**
* Creates a working analysis dataset containing containing only the relevant 
* records and variables for the current analysis.
* Required work datasets analset and groupingvars to already exist.
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param dsdd		Dataset to be used to determine data-driven groups.
* @param groupings	List of grouping IDs separated by '|'.
*/
%macro create_adwork ( mdlib=, datalib=, dsdd=, groupings= );

	* Standardize groupings;
	%standardize_grouping(dsgrp=&mdlib..analysisgroupings, 
		dsexpr=&mdlib..expressions, datalib=&datalib., dsdd=&dsdd., 
		ids=&groupings., dsout=adwork);

	* Restrict to the relevant analysis set;
	data adwork;
		merge analset ( in = a )
			adwork;
		by usubjid;
		if a;
	run;

%mend create_adwork;

*******************************************************************************;

/**
* Creates an outline analysis results dataset containing a row for every
* expected result for the specified analysis.
* The dataset is populated with metadata but no results data.
*
* @param mdlib		Library containing metadata datasets.
* @param analid		Analysis ID.
* @param dsvals		Dataset containing values of groups.
* @param dsout		Output dataset: outline ARD..
*/
%macro outline_ard ( mdlib=, analid=, dsvals=groupvalues, dsout= );

	%* Create an empty work version of the ARD;
	data &dsout.;
		set &mdlib..analysisresultstemplate;
	run;

	%* Insert a row for each expected result;
	proc sql;
		insert into &dsout.
			( id, analysisSet_label, method_id, method_label, 
				operation_id, operation_label, operation_resultPattern, 
				resultGroup1_groupingId, resultGroup1_groupId, 
				resultGroup1_group_label, 
				resultGroup2_groupingId, resultGroup2_groupId, 
				resultGroup2_group_label, 
				resultGroup3_groupingId, resultGroup3_groupId, 
				resultGroup3_group_label )
			select a.id, s.label, a.method_id, m.label, m.operation_id, 
					m.operation_label, m.operation_resultPattern, 
					g1.grouping_id, g1.groupValue, g1.groupLabel,
					g2.grouping_id, g2.groupValue, g2.groupLabel,
					g3.grouping_id, g3.groupValue, g3.groupLabel
				from &mdlib..analyses a join &mdlib..analysissets s 
					on a.analysisSetId = s.id
					join &mdlib..analysismethods m on a.method_id = m.id
					left join &dsvals. g1 on a.groupingId1 = g1.grouping_id
					left join &dsvals. g2 on a.groupingId2 = g2.grouping_id
					left join &dsvals. g3 on a.groupingId3 = g3.grouping_id
				where a.id = "&analid.";
	quit;

%mend outline_ard;

*******************************************************************************;

/**
* Execute an analysis operation:
* Operation ID:		Mth01_CatVar_Count_ByGrp_1_n
* Operation name:	Count of subjects
*
* @param mdlib		Library containing metadata datasets.
* @param ardlib		Library containing analysis results datasets.
* @param opid		Operation ID.
* @param opname		Operation name.
* @param oplabel	Operation label.
* @param oppatt		Operation result pattern.
* @param opord		Operation order within method.
* @param analid		Analysis ID.
* @param methid		Method ID.
* @param analvar	Analysis variable.
* @param grid1		Grouping 1 ID.
* @param gr1ids		List of group IDs for grouping 1.
* @param gr1labels	List of group labels for grouping 1.
* @param gr1conds	List of group conditions for grouping 1.
* @param grid2		Grouping 2 ID.
* @param gr2ids		List of group IDs for grouping 2.
* @param gr2labels	List of group labels for grouping 2.
* @param gr2conds	List of group conditions for grouping 2.
* @param grid3		Grouping 3 ID.
* @param gr3ids		List of group IDs for grouping 3.
* @param gr3labels	List of group labels for grouping 3.
* @param gr3conds	List of group conditions for grouping 3.
*/
%macro op_catvar_count_bygrp_n ( mdlib=, ardlib=, opid=, opname=, oplabel=, 
	oppatt=, opord=, analid=, methid=, analvar=, 
	grid1=, gr1ids=, gr1labels=, gr1conds=, 
	grid2=, gr2ids=, gr2labels=, gr2conds=, 
	grid3=, gr3ids=, gr3labels=, gr3conds= );

	%* Show operation details;
	%put NOTE: Operation &opid.: &opname.;
	%put NOTE:   Label: &oplabel.;
	%put NOTE:   Result pattern: &oppatt.;
	%put NOTE:   Order: &opord. in analysis &analid. method &methid.;

	* Build the tables request;
	%local tabreq;
	%let tabreq = &grid1.;
	%if &grid2. ne %str() %then %let tabreq = &tabreq. * &grid2.;
	%if &grid3. ne %str() %then %let tabreq = &tabreq. * &grid3.;

	%* Run the analysis;
	%if %sysfunc(exist(rawres)) %then %do;
		proc datasets library=work;
			delete rawres;
		run;
		quit;
	%end;
	proc freq data = adwork;
		tables &tabreq. / out = rawres;
	run;
	%if not %sysfunc(exist(rawres)) %then %do;
		data rawres;
			length NLevels 8;
			NLevels = 0;
		run;
	%end;

	%* Update the standard results dataset from the raw results dataset;
	proc sql;
		update analysisresults as a
			set rawValue = ( 
				select r.count 
					from rawres as r
					where a.resultGroup1_groupId = r.&grid1.
					%if &grid2. ne %str() %then %do;
						and a.resultGroup2_groupId = r.&grid2.
					%end;
					%if &grid3. ne %str() %then %do;
						and a.resultGroup3_groupId = r.&grid3.
					%end;
					)
			where a.id = "&analid." and a.method_id = "&methid." and
				a.operation_id = "&opid.";
	quit;

%mend op_catvar_count_bygrp_n;

*******************************************************************************;

/**
* Execute an analysis operation:
* Operation ID:		Mth01_CatVar_Summ_ByGrp_1_n
* Operation name:	Count of subjects
*
* @param mdlib		Library containing metadata datasets.
* @param ardlib		Library containing analysis results datasets.
* @param opid		Operation ID.
* @param opname		Operation name.
* @param oplabel	Operation label.
* @param oppatt		Operation result pattern.
* @param opord		Operation order within method.
* @param analid		Analysis ID.
* @param methid		Method ID.
* @param analvar	Analysis variable.
* @param grid1		Grouping 1 ID.
* @param gr1ids		List of group IDs for grouping 1.
* @param gr1labels	List of group labels for grouping 1.
* @param gr1conds	List of group conditions for grouping 1.
* @param grid2		Grouping 2 ID.
* @param gr2ids		List of group IDs for grouping 2.
* @param gr2labels	List of group labels for grouping 2.
* @param gr2conds	List of group conditions for grouping 2.
* @param grid3		Grouping 3 ID.
* @param gr3ids		List of group IDs for grouping 3.
* @param gr3labels	List of group labels for grouping 3.
* @param gr3conds	List of group conditions for grouping 3.
*/
%macro op_catvar_summ_bygrp_n ( mdlib=, ardlib=, opid=, opname=, oplabel=, 
	oppatt=, opord=, analid=, methid=, analvar=, 
	grid1=, gr1ids=, gr1labels=, gr1conds=, 
	grid2=, gr2ids=, gr2labels=, gr2conds=, 
	grid3=, gr3ids=, gr3labels=, gr3conds= );

	%* Show operation details;
	%put NOTE: Operation &opid.: &opname.;
	%put NOTE:   Label: &oplabel.;
	%put NOTE:   Result pattern: &oppatt.;
	%put NOTE:   Order: &opord. in analysis &analid. method &methid.;

	* Build the tables request;
	%local tabreq;
	%let tabreq = &grid1.;
	%if &grid2. ne %str() %then %let tabreq = &tabreq. * &grid2.;
	%if &grid3. ne %str() %then %let tabreq = &tabreq. * &grid3.;

	%* Run the analysis;
	%if %sysfunc(exist(rawres)) %then %do;
		proc datasets library=work;
			delete rawres;
		run;
		quit;
	%end;
	proc freq data = adwork;
		tables &tabreq. / out = rawres;
	run;
	%if not %sysfunc(exist(rawres)) %then %do;
		data rawres;
			length NLevels 8;
			NLevels = 0;
		run;
	%end;

	%* Update the standard results dataset from the raw results dataset;
	proc sql;
		update analysisresults as a
			set rawValue = ( 
				select r.count 
					from rawres as r
					where a.resultGroup1_groupId = r.&grid1.
					%if &grid2. ne %str() %then %do;
						and a.resultGroup2_groupId = r.&grid2.
					%end;
					%if &grid3. ne %str() %then %do;
						and a.resultGroup3_groupId = r.&grid3.
					%end;
					)
			where a.id = "&analid." and a.method_id = "&methid." and
				a.operation_id = "&opid.";
	quit;

%mend op_catvar_summ_bygrp_n;

*******************************************************************************;

/**
* Perform an analysis using the method:
* Method ID:	Mth01_CatVar_Count_ByGrp
* Method name:	Count by group for a categorical variable
* Method label:	Grouped count for categorical variable
* Method description: 
* Count across groups for a categorical variable, based on subject occurrence
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param ardlib			Library containing analysis results datasets.
* @param analid			Analysis ID.
* @param analname		Analysis name.
* @param analsetid		Analysis set ID.
* @param grid1			Grouping ID 1.
* @param bygr1			Whether results are required by group 1.
* @param grid2			Grouping ID 1.
* @param bygr2			Whether results are required by group 1.
* @param grid3			Grouping ID 1.
* @param bygr3			Whether results are required by group 1.
* @param datasubsetid	Data subset ID.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
*/
%macro mth_catvar_count_bygrp ( mdlib=, datalib=, ardlib=, methid=, analid=, 
	analname=, analsetid=, grid1=, bygr1=, grid2=, bygr2=, grid3=, bygr3=, 
	datasubsetid=, analds=, analvar= );

	%* Get method details;
	%local methid methname methlabel methdescr opids opnames opords oplabels
		oppatts;
	proc sql;
		select name, label, description into :methname, :methlabel, :methdescr
			from &mdlib..analysismethods
			where id = "&methid.";
		select operation_id, operation_name, operation_order, operation_label,
				operation_resultPattern
				into :opids separated by '|', :opnames separated by '|',
					:opords separated by '|', :oplabels separated by '|',
					:oppatts separated by '|'
			from &mdlib..analysismethods
			where id = "&methid.";
	quit;

	%* Show method details;
	%put NOTE: Method &methid.: &methname.;
	%put NOTE:   Description: &methdescr.;

	%* Get analysis set;
	%define_analset(mdlib=&mdlib., datalib=&datalib., analsetid=&analsetid.);

	* Build list of groupings;
	%local groupings;
	%let groupings = &grid1.;
	%if &grid2. ne %str() %then %let groupings = &groupings.|&grid2.;;
	%if &grid3. ne %str() %then %let groupings = &groupings.|&grid3.;;

	%* Create a work dataset containing the relevant records and variables;
	%create_adwork(mdlib=&mdlib., datalib=&datalib., dsdd=&analds., 
		groupings=&groupings.);

	%* Get the parameters required for the analysis;
	%local grpvars grpvarsx gr1ids gr1labels gr1conds 
		gr2ids gr2labels gr2conds 
		gr3ids gr3labels gr3conds
		datadriven opids;
	%let gr1ids = %str();
	%let gr1conds = %str();
	%let gr2ids = %str();
	%let gr2conds = %str();
	%let gr3ids = %str();
	%let gr3conds = %str();
	proc sql;
		select max(dataDriven) into :datadriven
			from &mdlib..analysisgroupings
			where id in ("&grid1.", "&grid2.", "&grid3.");
		select e.id, e.label, e.expression 
				into :gr1ids separated by '|', 
					:gr1labels separated by '|',
					:gr1conds separated by '|'
			from &mdlib..analysisgroupings g join &mdlib..expressions e
				on g.group_id = e.id
			where g.id = "&grid1.";
		%if &grid2. ne %str() %then %do;
			select e.id, e.label, e.expression 
					into :gr2ids separated by '|', 
						:gr2labels separated by '|',
						:gr2conds separated by '|'
				from &mdlib..analysisgroupings g join &mdlib..expressions e
					on g.group_id = e.id
				where g.id = "&grid2.";
		%end;
		%if &grid3. ne %str() %then %do;
			select e.id, e.label, e.expression 
					into :gr3ids separated by '|', 
						:gr3labels separated by '|',
						:gr3conds separated by '|'
				from &mdlib..analysisgroupings g join &mdlib..expressions e
					on g.group_id = e.id
				where g.id = "&grid3.";
		%end;
		select operation_id into :opids separated by '|'
			from &mdlib..analysismethods
			where id = "&methid."
			order by operation_order;
	quit;
	%let grpvarsx = %sysfunc(tranwrd(&grpvars.,%str( ),*));

	%* Create an work version of the ARD with a row for each expected result;;
	%outline_ard(mdlib=&mdlib., analid=&analid., dsout=work.analysisresults);

	%* Loop through analysis operations;
	%local iop opid opname opord oplabel oppatt;
	%let iop = 1;
	%do %while(%scan(&opids., &iop., '|') ne );
		%let opid = %scan(&opids., &iop., '|');
		%let opname = %scan(&opnames., &iop., '|');
		%let opord = %scan(&opords., &iop., '|');
		%let oplabel = %scan(&oplabels., &iop., '|');
		%let oppatt = %scan(&oppatt., &iop., '|');

		%* Execute this operation;
		%if &opid. = Mth01_CatVar_Count_ByGrp_1_n %then %do;
			%op_catvar_count_bygrp_n(mdlib=&mdlib., ardlib=&ardlib., 
				analid=&analid., methid=&methid., opord=&opord., opid=&opid., 
				opname=&opname., oplabel=&oplabel., oppatt=&oppatt.,
				analvar=&analvar., 
				grid1=&grid1., gr1ids=&gr1ids., gr1labels=&gr1labels., 
				gr1conds=&gr1conds., 
				grid2=&grid2., gr2ids=&gr2ids., gr2labels=&gr2labels., 
				gr2conds=&gr2conds., 
				grid3=&grid3., gr3ids=&gr3ids., gr3labels=&gr3labels., 
				gr3conds=&gr3conds.);
		%end;
		%else %do;
			%put WARNING: Operation &opid. is not supported.;
		%end;

		%let iop = %eval(&iop.+1);
	%end;

	* Append work ARD to main ARD;
	proc append base = &ardlib..analysisresults data = analysisresults;
	run;
	quit;

%mend mth_catvar_count_bygrp;

*******************************************************************************;

/**
* Perform an analysis using the method:
* Method ID:	Mth01_CatVar_Summ_ByGrp
* Method name:	Summary by group of a categorical variable
* Method label:	Grouped summary of categorical variable
* Method description: 
* Descriptive summary statistics across groups for a categorical variable, 
* based on subject occurrence
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param ardlib			Library containing analysis results datasets.
* @param analid			Analysis ID.
* @param analname		Analysis name.
* @param analsetid		Analysis set ID.
* @param grid1			Grouping ID 1.
* @param bygr1			Whether results are required by group 1.
* @param grid2			Grouping ID 1.
* @param bygr2			Whether results are required by group 1.
* @param grid3			Grouping ID 1.
* @param bygr3			Whether results are required by group 1.
* @param datasubsetid	Data subset ID.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
*/
%macro mth_catvar_summ_bygrp ( mdlib=, datalib=, ardlib=, methid=, analid=, 
	analname=, analsetid=, grid1=, bygr1=, grid2=, bygr2=, grid3=, bygr3=, 
	datasubsetid=, analds=, analvar= );

	%* Get method details;
	%local methid methname methlabel methdescr opids opnames opords oplabels
		oppatts;
	proc sql;
		select name, label, description into :methname, :methlabel, :methdescr
			from &mdlib..analysismethods
			where id = "&methid.";
		select operation_id, operation_name, operation_order, operation_label,
				operation_resultPattern
				into :opids separated by '|', :opnames separated by '|',
					:opords separated by '|', :oplabels separated by '|',
					:oppatts separated by '|'
			from &mdlib..analysismethods
			where id = "&methid.";
	quit;

	%* Show method details;
	%put NOTE: Method &methid.: &methname.;
	%put NOTE:   Description: &methdescr.;

	%* Get analysis set;
	%define_analset(mdlib=&mdlib., datalib=&datalib., analsetid=&analsetid.);

	* Build list of groupings;
	%local groupings;
	%let groupings = &grid1.;
	%if &grid2. ne %str() %then %let groupings = &groupings.|&grid2.;;
	%if &grid3. ne %str() %then %let groupings = &groupings.|&grid3.;;

	%* Create a work dataset containing the relevant records and variables;
	%create_adwork(mdlib=&mdlib., datalib=&datalib., dsdd=&analds., 
		groupings=&groupings.);

	%* Get the parameters required for the analysis;
	%local grpvars grpvarsx gr1ids gr1labels gr1conds 
		gr2ids gr2labels gr2conds 
		gr3ids gr3labels gr3conds
		datadriven opids;
	%let gr1ids = %str();
	%let gr1conds = %str();
	%let gr2ids = %str();
	%let gr2conds = %str();
	%let gr3ids = %str();
	%let gr3conds = %str();
	proc sql;
		select max(dataDriven) into :datadriven
			from &mdlib..analysisgroupings
			where id in ("&grid1.", "&grid2.", "&grid3.");
		select e.id, e.label, e.expression 
				into :gr1ids separated by '|', 
					:gr1labels separated by '|',
					:gr1conds separated by '|'
			from &mdlib..analysisgroupings g join &mdlib..expressions e
				on g.group_id = e.id
			where g.id = "&grid1.";
		%if &grid2. ne %str() %then %do;
			select e.id, e.label, e.expression 
					into :gr2ids separated by '|', 
						:gr2labels separated by '|',
						:gr2conds separated by '|'
				from &mdlib..analysisgroupings g join &mdlib..expressions e
					on g.group_id = e.id
				where g.id = "&grid2.";
		%end;
		%if &grid3. ne %str() %then %do;
			select e.id, e.label, e.expression 
					into :gr3ids separated by '|', 
						:gr3labels separated by '|',
						:gr3conds separated by '|'
				from &mdlib..analysisgroupings g join &mdlib..expressions e
					on g.group_id = e.id
				where g.id = "&grid3.";
		%end;
		select operation_id into :opids separated by '|'
			from &mdlib..analysismethods
			where id = "&methid."
			order by operation_order;
	quit;
	%let grpvarsx = %sysfunc(tranwrd(&grpvars.,%str( ),*));

	%* Create an work version of the ARD with a row for each expected result;;
	%outline_ard(mdlib=&mdlib., analid=&analid., dsout=work.analysisresults);

	%* Loop through analysis operations;
	%local iop opid opname opord oplabel oppatt;
	%let iop = 1;
	%do %while(%scan(&opids., &iop., '|') ne );
		%let opid = %scan(&opids., &iop., '|');
		%let opname = %scan(&opnames., &iop., '|');
		%let opord = %scan(&opords., &iop., '|');
		%let oplabel = %scan(&oplabels., &iop., '|');
		%let oppatt = %scan(&oppatt., &iop., '|');

		%* Execute this operation;
		%if &opid. = Mth01_CatVar_Summ_ByGrp_1_n %then %do;
			%op_catvar_summ_bygrp_n(mdlib=&mdlib., ardlib=&ardlib., 
				analid=&analid., methid=&methid., opord=&opord., opid=&opid., 
				opname=&opname., oplabel=&oplabel., oppatt=&oppatt.,
				analvar=&analvar., 
				grid1=&grid1., gr1ids=&gr1ids., gr1labels=&gr1labels., 
				gr1conds=&gr1conds., 
				grid2=&grid2., gr2ids=&gr2ids., gr2labels=&gr2labels., 
				gr2conds=&gr2conds., 
				grid3=&grid3., gr3ids=&gr3ids., gr3labels=&gr3labels., 
				gr3conds=&gr3conds.);
		%end;
		%else %do;
			%put WARNING: Operation &opid. is not supported.;
		%end;

		%let iop = %eval(&iop.+1);
	%end;

	* Append work ARD to main ARD;
	proc append base = &ardlib..analysisresults data = analysisresults;
	run;
	quit;

%mend mth_catvar_summ_bygrp;

*******************************************************************************;

/**
* Run a single analysis.
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param ardlib		Library containing analysis results datasets.
* @param analid		Analysis ID.
* @param debugfl	Debug flag (Y/N).
*/
%macro run_analysis ( mdlib=, datalib=, ardlib=, analid=, debugfl=N );

	* Get analysis details;
	%local analname analsetid grid1 bygr1 grid2 bygr2 grid3 bygr3 datasubsetid 
		analds analvar methid analreas analpurp;
	proc sql;
		select name, analysisSetId, groupingId1, resultsByGroup1, 
					groupingId2, resultsByGroup2, 
					groupingId3, resultsByGroup3, 
					dataSubsetId, dataset, variable, method_id, reason, purpose
				into :analname, :analsetid, :grid1, :bygr1, :grid2, :bygr2, 
					:grid3, :bygr3, :datasubsetid, :analds, :analvar, :methid,
					:analreas, :analpurp
			from &mdlib..analyses
			where id = "&analid.";
	quit;
	%let bygr1 = &bygr1.;
	%let bygr2 = &bygr2.;
	%let bygr3 = &bygr3.;

	* Show analysis details;
	%put NOTE: Analysis &analid.: &analname.;
	%put NOTE:   Analysis set: &analsetid.;
	%if &grid1. ne %str() %then %put NOTE:   Grouping 1: &grid1. (&bygr1.);
	%if &grid2. ne %str() %then %put NOTE:   Grouping 2: &grid2. (&bygr2.);
	%if &grid3. ne %str() %then %put NOTE:   Grouping 3: &grid3. (&bygr3.);
	%if &datasubsetid. ne %str() %then %put NOTE:   Data subset: &datasubsetid.;
	%put NOTE:   Dataset: &analds.;
	%put NOTE:   Variable: &analvar.;
	%put NOTE:   Method: &methid.;
	%put NOTE:   Reason: &analreas.;
	%put NOTE:   Purpose: &analpurp.;

	* Call appropriate analysis macro;
	%if &methid. = Mth01_CatVar_Count_ByGrp %then %do;
		%mth_catvar_count_bygrp(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib., 
			methid=&methid., analid=&analid., analname=&analname., 
			analsetid=&analsetid., grid1=&grid1., bygr1=&bygr1., 
			grid2=&grid2., bygr2=&bygr2., grid3=&grid3., bygr3=&bygr3., 
			datasubsetid=&datasubsetid., analds=&analds., analvar=&analvar.);

	%end;
	%else %if &methid. = Mth01_CatVar_Summ_ByGrp %then %do;
		%mth_catvar_summ_bygrp(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib., 
			methid=&methid., analid=&analid., analname=&analname., 
			analsetid=&analsetid., grid1=&grid1., bygr1=&bygr1., 
			grid2=&grid2., bygr2=&bygr2., grid3=&grid3., bygr3=&bygr3., 
			datasubsetid=&datasubsetid., analds=&analds., analvar=&analvar.);

	%end;
	%else %do;
		%put WARNING: Method &methid. is not supported.;
	%end;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete adwork analset analysisresults grouping rawres;
		run;
		quit;
	%end;

%mend run_analysis;

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
data ard.analysisresults;
	set ard.analysisresultstemplate;
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
proc sort data = ard.analysisresults;
	by id method_id operation_id resultgroup1_groupid resultgroup2_groupid 
		resultgroup3_groupid;
run;

* Direct log output back to the log window;
proc printto;
run; 
