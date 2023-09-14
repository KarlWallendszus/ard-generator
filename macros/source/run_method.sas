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
	%put NOTE: Method &methid.: %bquote(&methname.);
	%put NOTE:   In analysis &analid.;
	%put NOTE:   Label: %bquote(&methlabel.);
	%put NOTE:   Description: %bquote(&methdescr.);
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
		%run_operation(mdlib=&mdlib., datalib=&datalib., 
			opid=&&opid&iop., methid=&methid., analid=&analid., 
			analsetid=&analsetid., datasubsetid=&datasubsetid., 
			groupingids=&groupingids., analds=workds, analvar=&analvar., 
			ard=&ardlib..ard, debugfl=&debugfl.);

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
