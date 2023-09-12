/*!
********************************************************************************
* Run a single analysis operation.
* @author Karl Wallendszus
* @created 2023-08-01
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param opid			Operation ID.
* @param methid			Method ID.
* @param analid			Analysis ID.
* @param analsetid		Analysis set ID.
* @param datasubsetid	Data subset ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
* @param ard			Analysis results dataset.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro run_operation ( mdlib=, datalib=, opid=, methid=, analid=, analsetid=, 
datasubsetid=, groupingids=, analds=, analvar=, ard=, debugfl=N );

	%* Get operation details;
	%local opname opord oplabel oppatt 
		nrels relids relroles relopids reldescrs;
	proc sql;
		select operation_name, operation_order, operation_label, 
				operation_resultPattern 
			into :opname, :opord, :oplabel, :oppatt
			from &mdlib..methodoperations
			where operation_id = "&opid.";
		select count(*) into :nrels
			from &mdlib..operationsrefop
			where operation_id = "&opid.";
		select refOpRel_id, refOpRel_refOperationRole, refOpRel_operationId
				into :relids separated by '|', :relroles separated by '|', 
					:relopids separated by '|'
			from &mdlib..operationsrefop
			where operation_id = "&opid."
			order by 1;
	quit;

	* Extract referenced operation relationship details into separate macro variables;
	%local irel;
	%do irel = 1 %to &nrels.;
		%local relid&irel. relrole&irel relopid&irel. reldescr&irel.;
		%let relid&irel. = %scan(&relids., &irel., '|');
		%let relrole&irel. = %scan(&relroles., &irel., '|');
		%let relopid&irel. = %scan(&relopids., &irel., '|');
	%end;

	%* Show operation details;
	%put NOTE: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;
	%put NOTE: Operation &opid.: &opname.;
	%put NOTE:   In method &methid. of analysis &analid.;
	%put NOTE:   Order: &opord.;
	%put NOTE:   Label: &oplabel.;
	%put NOTE:   Result pattern: &oppatt.;
	%do irel = 1 %to &nrels.;
		%put NOTE:   Referenced operation relationship: &&relid&irel.;
		%put NOTE:     Role: &&relrole&irel.;
		%put NOTE:     Operation ID: &&relopid&irel.;
	%end;

	%* Create a work version of the ARD with a row for each expected result;
	%outline_ard(ardlib=work, mdlib=&mdlib., analid=&analid., opid=&opid.,
		groupingids=&groupingids., dsin=&analds., dsout=work.ard);

	%* Execute this operation;
	%if &opid. = Mth01_CatVar_Count_ByGrp_1_n 
			or &opid. = Mth01_CatVar_Summ_ByGrp_1_n %then %do;
		%op_catvar_count_bygrp_n(analid=&analid., methid=&methid., opid=&opid., 
			groupingids=&groupingids., dsin=&analds., dsout=work.ard, 
			debugfl=&debugfl.);
	%end;
	%else %if &opid. = Mth01_CatVar_Summ_ByGrp_2_pct %then %do;

		%local irel_num irel_den;
		%do irel = 1 %to &nrels.;
			%if &&relrole&irel. = NUMERATOR %then %let irel_num = &irel.;
			%else %if &&relrole&irel. = DENOMINATOR %then %let irel_den = &irel.;
		%end;
		%local num_analid den_analid;
		proc sql;
			select a.analysisid into :num_analid
				from &mdlib..analysesrefoperations a
				where a.id = "&analid" and 
					a.referencedoperationrelationshipi = "&&relid&irel_num.";
			select a.analysisid into :den_analid
				from &mdlib..analysesrefoperations a
				where a.id = "&analid" and 
					a.referencedoperationrelationshipi = "&&relid&irel_den.";
		quit;

		%put NOTE: NUM &&relid&irel_num. &num_analid. &&relopid&irel_num.;
		%put NOTE: DEN &&relid&irel_den. &den_analid. &&relopid&irel_den.;

		%op_catvar_summ_bygrp_pct(analid=&analid., methid=&methid., opid=&opid., 
			groupingids=&groupingids., 
			num_analid=&num_analid., num_opid=&&relopid&irel_num., 
			den_analid=&den_analid., den_opid=&&relopid&irel_den., 
			ardin=&ard., dsout=work.ard, debugfl=&debugfl.);
	%end;
	%else %do;
		%put WARNING: Operation &opid. is not supported.;
	%end;

	* Append work ARD to main ARD;
	%append_addcols(dsbase=&ard., dsnew=work.ard);

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete ard;
		run;
		quit;
	%end;

	* Write completion message to log;
	%put NOTE: Operation &opid. completed;
	%put NOTE: - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;

%mend run_operation;

*******************************************************************************;
