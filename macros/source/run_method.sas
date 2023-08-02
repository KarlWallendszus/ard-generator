﻿/*!
********************************************************************************
* Run a single analysis method.
* @author Karl Wallendszus
* @created 2023-08-01
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param ardlib			Library containing analysis results datasets.
* @param methid			Method ID.
* @param analid			Analysis ID.
* @param analsetid		Analysis set ID.
* @param datasubsetid	Data subset ID.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro run_method ( mdlib=, datalib=, ardlib=, methid=, analid=, 
	analsetid=, datasubsetid=, analds=, analvar=, debugfl=N );

	%* Get operation details;
	%local methid methname methlabel methdescr 
		noperations opords opids;
	proc sql;
		select name, label, description into :methname, :methlabel, :methdescr
			from &mdlib..analysismethods
			where id = "&methid.";
		select count(*) into :noperations
			from &mdlib..methodoperations
			where id = "&methid.";
		select operation_order, operation_id 
				into :opords separated by '|', :opids separated by '|'
			from &mdlib..methodoperations
			where id = "&methid."
			order by 1;
	quit;

	* Extract operation details into separate macro variables;
	%local iop;
	%do iop = 1 %to &noperations.;
		%local opord&iop. opid&iop.;
		%let opord&iop. = %scan(&opords., &iop., '|');
		%let opid&iop. = %scan(&opids., &iop., '|');
	%end;

	%* Show method details;
	%put NOTE: --------------------------------------------------------------------------------;
	%put NOTE: Method &methid.: &methname.;
	%put NOTE:   In analysis &analid.;
	%put NOTE:   Label: &methlabel.;
	%put NOTE:   Description: &methdescr.;
	%do iop = 1 %to &noperations.;
		%put NOTE:   Operation &&opord&iop.: &&opid&iop.;
	%end;

	/*	
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
	*/

	%* Loop through analysis operations;
	%do iop = 1 %to &noperations.;


		/*
		%* Create a work version of the ARD with a row for each expected result;;
		%outline_ard(ardlib=&ardlib., mdlib=&mdlib., analid=&analid., methid=&methid.,
			opid=&opid., dsout=work.analysisresults);
		*/

		%* Execute this operation;
		%run_operation(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib., 
			opid=&&opid&iop., methid=&methid., analid=&analid., 
			analsetid=&analsetid., datasubsetid=&datasubsetid., 
			analds=&analds., analvar=&analvar., debugfl=&debugfl.);

		/*
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
		%else %if &opid. = Mth01_CatVar_Summ_ByGrp_1_n %then %do;
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
		*/

	%end;

	/*

	* Append work ARD to main ARD;
	proc append base = &ardlib..analysisresults data = analysisresults;
	run;
	quit;

	*/

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		/*
		proc datasets library=work;
			delete adwork analset analysisresults grouping rawres;
		run;
		quit;
		*/
	%end;

	* Write completion message to log;
	%put NOTE: Method &methid. completed;
	%put NOTE: --------------------------------------------------------------------------------;

%mend run_method;

*******************************************************************************;
