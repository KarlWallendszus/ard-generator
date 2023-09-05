/*!
********************************************************************************
* Builds a working analysis dataset, having applied the relevant analysis set,
* data subset and groupings.
* @author Karl Wallendszus
* @created 2023-08-02
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
* @param analsetid		Analysis set ID.
* @param datasubsetid	Data subset ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param fmtlib			Library in which to store formats created.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro build_work_dataset ( mdlib=, datalib=, analds=, analvar=, analsetid=, 
	datasubsetid=, groupingids=, fmtlib=work, debugfl=N );

	%* Define the analysis set;
	%define_analset(mdlib=&mdlib., datalib=&datalib., analsetid=&analsetid.);

	%* Create a dataset to hold a list of the variables needed in the working 
	dataset;
	data reqvars;
		length dataset variable $8;
		stop;
	run;

	%* Add the analysis variable;
	proc sql;
		insert into reqvars
			( dataset, variable )
			values ("&analds.", "&analvar");
	quit;

	%* Add variables used in the data subset (if any);
	proc sql;
		insert into reqvars
			( dataset, variable )
			select condition_dataset, condition_variable
				from &mdlib..datasubsets
				where id = "&datasubsetid." and condition_variable is not null;
	quit;

	%* Add variables used in the data groupings (if any);
	%local ig groupingid;
	%let ig = 1;
	%do %while(%scan(&groupingids., &ig., '|') ne );
		%let groupingid = %scan(&groupingids., &ig., '|');
		proc sql;
			insert into reqvars
				( dataset, variable )
				select distinct group_condition_dataset, group_condition_variable
					from &mdlib..analysisgroupings
					where id = "&groupingid." and group_condition_dataset is not null;
			insert into reqvars
				( dataset, variable )
				select distinct "&analds.", groupingVariable
					from &mdlib..analysisgroupings
					where id = "&groupingid." and group_condition_dataset is null;
		quit;
		%let ig = %eval(&ig.+1);
	%end;

	%* Assume the datasets are joied by USUBJID so add this for each dataset; 
	proc sql;
		create table reqvarstmp
			as select distinct upper(dataset) as dataset, 'USUBJID' as variable
				from reqvars
				where variable ^= 'USUBJID';
		insert into reqvars
			( dataset, variable )
			select dataset, variable
				from reqvarstmp;
		drop table reqvarstmp;
	quit;

	%* Create lists of distinct datasets amd variables;
	%local dslist nds;
	proc sql;
		create table reqvars1
			as select distinct upper(dataset) as dataset, 
					upper(variable) as variable
				from reqvars;
		select count(distinct dataset) into :nds
			from reqvars1;
		select distinct dataset into :dslist separated by ' '
			from reqvars1;
	quit;

	%* Now build a dataset containing all these variables for subjects in the analysis set;

	%* Loop through datasets;
	%local ids iv;
	%do ids = 1 %to &nds.;
		%local ds&ids. ds&ids.vars;
		%let ds&ids. = %scan(&dslist., &ids., ' ');
		%put NOTE: Merging dataset &ids.: &&ds&ids.;

		%* Get list of required variables in this dataset;
		proc sql;
			select variable into :ds&ids.vars separated by ' '
				from reqvars1
				where dataset = "&&ds&ids.";
		quit;
		%put NOTE: Variables in &&ds&ids.: &&ds&ids.vars.;

		%* Merge this dataset with the analysis set;
		%if &ids. = 1 %then %do;
			data workds;
				set analset;
			run;
		%end;
		data workds;
			merge workds ( in = w )
				&datalib..&&ds&ids. ( in = d keep = &&ds&ids.vars. );
			by usubjid;
			if w and d;
		run;
	%end;

	%* Apply data subsets;
	%if &datasubsetid. ne %str() %then %do;
		proc sql;
			select expression into :dssexpr
				from &datalib..expressions
				where id = "&datasubsetid.";
		quit;
		%let dssexpr = &dssexpr.;
		data workds;
			set workds ( where = ( &dssexpr. ) );
		run;
	%end;

	%* Standardise groupings;
	%if "&groupingids." ne %str() %then %do;
		%standardize_groupings(dsgrp=testdata.analysisgroupings, 
			dsexpr=testdata.expressions, dsin=workds, 
			ids=&groupingids., dsout=workds_g, fmtlib=&fmtlib., 
			debugfl=&debugfl.);
		data workds;
			set workds_g;
		run;
	%end;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete analset reqvars reqvars1 workds_g;
		run;
		quit;
	%end;

%mend build_work_dataset;

*******************************************************************************;
