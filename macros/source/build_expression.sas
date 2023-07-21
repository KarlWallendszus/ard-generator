/*!
* Generate an expression string for a given condition.
* @author Karl Wallendszus
* @created 2023-05-22
*/
*******************************************************************************;
/**
* Generate an expression string for a given condition.
* Assumes the output dataset already exists.
* Access to the datasets containing the data to which the expression will be 
* applied is needed in order to determine whether the referenced variables are
* character or numeric.
*
* @param dsin		Input dataset containing expression definition.
* @param idvar		Variable in input dataset containing the expression ID.
* @param labelvar	Variable in input dataset containing the expression label.
* @param levelvar	Variable in input dataset containing the clause level.
* @param ordervar	Variable in input dataset containing the clause order.
* @param logopvar	Variable in input dataset containing the logical operator.
* @param dsvar		Variable in input dataset containing the compared dataset.
* @param varvar		Variable in input dataset containing the compared variable.
* @param compvar	Variable in input dataset containing the comparator.
* @param valvar		Variable in input dataset containing the compared value.
* @param id			Expression ID.
* @param datalib	Library containing data to which the expression will be applied.
* @param dsout		Output dataset for condition string.
*/
%macro build_expression ( dsin=, idvar=id, labelvar=label, levelvar=level, 
	ordervar=order, logopvar=compndExpression_logicalOperator,
	dsvar=condition_dataset, varvar=condition_variable, 
	compvar=condition_comparator, valvar=condition_value, id=,
	datalib=, dsout= );

	* Get expression label;
	%local nrows nlevels explabel;
	proc sql;
		select count(distinct &labelvar.), max(&levelvar.) 
				into :nrows, :nlevels
			from &dsin.
			where &idvar. = "&id.";
		select distinct &labelvar. into :explabel
			from &dsin.
			where &idvar. = "&id.";
	quit;
	%if &nrows. = 0 %then %do;
		%put ERROR: No expression with ID &id. found in &dsin. dataset.;
		%return;
	%end;
	%else %do;
		%put NOTE: Expression ID: &id.;
		%put NOTE: Expression label: &explabel.;
		%put NOTE: Number of rows: &nrows.;
		%put NOTE: Number of levels: &nlevels.;
	%end;

	* Copy records for this expression to a work dataset;
	proc sql;
		create table conddef
			as select &idvar. as id, &labelvar. as label, &levelvar. as level, 
					&ordervar. as order, &logopvar. as logop,
					&dsvar. as dscond, &varvar. as condvar, &compvar. as condcomp, 
					&valvar. as condval, '' as clause length=200
				from &dsin.
				where &idvar. = "&id.";
	quit;

	* Get list of referenced datasets;
	%local dslist;
	proc sql;
		select distinct dscond into :dslist separated by ' '
			from conddef
			where dscond is not null
			order by 1;
	quit;
	* Generate clause strings for all the simple clauses,;
	* i.e. those without a compound expression logical operator.;

	* Get condition details;
	%local clevels corders dsconds condvars condcomps condvals
		clevel corder dscond condvar condcomp condval cstr;
	proc sql;
		select level, order, dscond, condvar, condcomp, condval
				into :clevels separated by '|', :corders separated by '|',
					:dsconds separated by '|', :condvars separated by '|', 
					:condcomps separated by '|', :condvals separated by '#'
			from conddef
			where logop is null;
	quit;

	* Loop through records;
	%local irec ival val valstr;
	%let irec = 1;
	%do %while(%scan(&clevels., &irec., '|') ne );
		%let clevel = %scan(&clevels., &irec., '|');
		%let corder = %scan(&corders., &irec., '|');
		%let dscond = %scan(&dsconds., &irec., '|');
		%let condvar = %scan(&condvars., &irec., '|');
		%let condcomp = %scan(&condcomps., &irec., '|');
		%let condval = %scan(&condvals., &irec., '#');

		* Is the variable character or numeric?;
		* Sets macro variable var_type: C=character, N=numeric;
		%local rc dsid var_num var_type;
		%let var_type = %str();
		%let dsid = %sysfunc(open(&datalib..&dscond.));
		%let var_num = %sysfunc(varnum(&dsid., &condvar.));
		%let var_type = %sysfunc(vartype(&dsid., &var_num.));
		%let rc = %sysfunc(close(&dsid.));

		* Build the clause string;
		%if &condcomp. = IN %then %do;
			%let valstr = (;
			%let ival = 1;
			%do %while(%scan(&condval., &ival., '|') ne );
				%let val = %scan(&condval., &ival., '|');
				%if &var_type. = C %then %do;
					%if &ival. = 1 %then %do;
						%let valstr = %str(&valstr.%"&val.%");
					%end;
					%else %do;
						%let valstr = %str(&valstr., %"&val.%");
					%end;
				%end;
				%else %do;
					%if &ival. = 1 %then %do;
						%let valstr = &valstr.&val.;
					%end;
					%else %do;
						%let valstr = &valstr., &val.;
					%end;
				%end;
				%let ival = %eval(&ival.+1);
			%end;
			%let valstr = &valstr.);
			%let cstr = &condvar. &condcomp. &valstr.;
		%end;
		%else %do;
			%if &var_type. = C %then %do;
				%let cstr = %str(&condvar. &condcomp. %"&condval.%");
			%end;
			%else %do;
				%let cstr = &condvar. &condcomp. &condval.;
			%end;
		%end;

		* Update work dataset with clause string;
		proc sql;
			update conddef
				set clause = "&cstr."
				where level = &clevel. and order = &corder.;
		quit;

		%let irec = %eval(&irec.+1);
	%end;

	* Build compound expressions by connecting clauses of the same level;
	* from lowest to highest level.;
	%local ilevel ichildlevel childclauses logops logop 
		nclauses clauses iclause clause
		icclause childclause compclause;
	%let childlevel = childclauses;
	%do ilevel = &nlevels. %to 1 %by -1;
		
		* Retrieve data for this level;
		proc sql;
			select count(*)	into :nclauses
				from conddef
				where level = &ilevel.;
			select logop, clause
					into :logops separated by '|', :clauses separated by '#'
				from conddef
				where level = &ilevel.
				order by order;
		quit;

		%put NOTE: &ilevel. [&logops.] [&clauses.];

		* Loop through clauses at this level;
		%do iclause = 1 %to &nclauses.;
			%let logop = %scan(&logops., &iclause., '|');
			%let clause = %qscan(&clauses., &iclause., '#');

			%put NOTE: level &ilevel. clause &iclause. logop=[&logop.] clause=[&clause.];

			* If this clause has a logical operator, use it to connect the 
			clauses in the child level;
			%if "&logop." ^= "" %then %do;
		
				* Retrieve child clauses;
				proc sql;
					select clause
							into :childclauses separated by '#'
						from conddef
						where level = &ichildlevel. and clause ^= ""
						order by order;
				quit;

				* Loop through child clauses;
				%let icclause = 1;
				%do %while(%qscan(&childclauses., &icclause., '#') ne );
					%let childclause = %qscan(&childclauses., &icclause., '#');
					%if &icclause. = 1 %then %do;
						%let compclause = (&childclause.);
					%end;
					%else %do;
						%let compclause = &compclause. &logop. (&childclause.);
					%end;
					%let icclause = %eval(&icclause.+1);
				%end;
	
				%put NOTE: &ilevel. &iclause. compclause=[&compclause.];

				* Update work dataset with clause string;
				proc sql;
					update conddef
						set clause = "&compclause."
						where level = &ilevel. and logop = "&logop.";
				quit;
			%end;

		%end;

		* Set current level as child of the next;
		%let ichildlevel = &ilevel.;
	%end;

	* Insert top level clause into output dataset;
	proc sql;
		insert into &dsout.
			( id, label, dsconds, expression )
			select id, label, "&dslist.", clause
				from conddef
				where level = 1 and clause is not null;
	quit;

	* Tidy up;
	proc datasets library=work;
		delete conddef;
	run;
	quit;

%mend build_expression;

*******************************************************************************;
