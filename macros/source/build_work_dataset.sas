/*!
********************************************************************************
* Builds a working analysis dataset, having applied the relevant analysis set,
* data subset and groupings.
* @author Karl Wallendszus
* @created 2023-08-02
*
* @param mdlib			Library containing metadata datasets.
* @param datalib		Library containing data to be analysed.
* @param ardlib			Library containing analysis results datasets.
* @param methid			Method ID.
* @param analid			Analysis ID.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
* @param analsetid		Analysis set ID.
* @param datasubsetid	Data subset ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro build_work_dataset ( mdlib=, datalib=, ardlib=, methid=, analid=, 
	analds=, analvar=, analsetid=, datasubsetid=, groupingids=, debugfl=N );

	* Create a dataset to hold a list of the variables needed in the working 
	dataset;
	data reqvars;
		length dataset variable $8;
		stop;
	run;

	* Add USUBJID and the analysis variable;
	proc sql;
		insert into reqvars
			( dataset, variable )
			values ("&analds.", "USUBJID");
		insert into reqvars
			( dataset, variable )
			values ("&analds.", "&analvar");
	quit;

	* Add variables used in the data subset (if any);
	proc sql;
		insert into reqvars
			( dataset, variable )
			select condition_dataset, condition_variable
				from &mdlib..datasubsets
				where id = "&datasubsetid." and condition_variable is not null;
	quit;

	%* Define the analysis set;
	%define_analset(mdlib=&mdlib., datalib=&datalib., analsetid=&analsetid.);

	* Add variables used in the data groupings (if any);
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

	* Create a list of distinct variables;
	proc sql;
		create table reqvars1
			as select distinct upper(dataset) as dataset, 
					upper(variable) as variable
				from reqvars;
	quit;

	/*

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

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete analset reqvars;
		run;
		quit;
	%end;

%mend build_work_dataset;

*******************************************************************************;
