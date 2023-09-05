/*!
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
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro run_method ( mdlib=, datalib=, ardlib=, methid=, analid=, 
	analsetid=, datasubsetid=, analds=, analvar=, groupingids=, debugfl=N );

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

	%* Extract operation details into separate macro variables;
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

	%* Build a work dataset including all relevant variables;
	%build_work_dataset(mdlib=&mdlib., datalib=&datalib., analds=&analds., 
		analvar=&analvar., analsetid=&analsetid., 
		datasubsetid=&datasubsetid., groupingids=&groupingids., 
		fmtlib=&ardlib., debugfl=&debugfl.);

	%* Loop through analysis operations;
	%do iop = 1 %to &noperations.;

		%* Execute this operation;
		%run_operation(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib., 
			opid=&&opid&iop., methid=&methid., analid=&analid., 
			analsetid=&analsetid., datasubsetid=&datasubsetid., 
			groupingids=&groupingids., analds=&analds., analvar=&analvar., 
			debugfl=&debugfl.);

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

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete workds;
		run;
		quit;
	%end;

	* Write completion message to log;
	%put NOTE: Method &methid. completed;
	%put NOTE: --------------------------------------------------------------------------------;

%mend run_method;

*******************************************************************************;
