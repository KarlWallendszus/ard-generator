/*!
********************************************************************************
* Run a single analysis operation.
* @author Karl Wallendszus
* @created 2023-08-01
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param opid			Operation ID.
* @param opseq			Sequence number of operation within the current method.
* @param nop			Number of operations within the current method.
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
%macro run_operation ( mdlib=, datalib=, opid=, opseq=, nop=, methid=, analid=, 
	analsetid=, datasubsetid=, groupingids=, analds=, analvar=, ard=, 
	debugfl=N );

	%* Enable the macro IN operator;
	options minoperator;

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
	%put NOTE: Operation &opid.: %bquote(&opname.);
	%put NOTE:   In method &methid. of analysis &analid.;
	%put NOTE:   Order: &opord. (&opseq./&nop.);
	%put NOTE:   Label: %bquote(&oplabel.);
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

		%op_catvar_summ_bygrp_pct(analid=&analid., methid=&methid., opid=&opid., 
			groupingids=&groupingids., 
			num_analid=&num_analid., num_opid=&&relopid&irel_num., 
			den_analid=&den_analid., den_opid=&&relopid&irel_den., 
			ardin=&ard., dsout=work.ard, debugfl=&debugfl.);
	%end;
	%else %if &opid. in Mth02_ContVar_Summ_ByGrp_1_n
				Mth02_ContVar_Summ_ByGrp_2_Mean
				Mth02_ContVar_Summ_ByGrp_3_SD
				Mth02_ContVar_Summ_ByGrp_4_Median
				Mth02_ContVar_Summ_ByGrp_5_Q1
				Mth02_ContVar_Summ_ByGrp_6_Q3
				Mth02_ContVar_Summ_ByGrp_7_Min
				Mth02_ContVar_Summ_ByGrp_8_Max
			%then %do;
		%local mode;
		%if &opseq. = 1 %then %let mode = GEN;
		%else %if &opseq. = &nop. %then %let mode = DEL;
		%else %let mode = RET;
		%op_contvar_summ_bygrp(analid=&analid., methid=&methid., opid=&opid.,
			oplabel=&oplabel., groupingids=&groupingids., mode=&mode.,
			dsin=&analds., analvar=&analvar., dsout=work.ard, debugfl=&debugfl.);
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
