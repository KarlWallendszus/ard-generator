/*!
********************************************************************************
* Appends a new dataset to a base dataset and adds any columns in the new
* new datset that are missing from the base dataset.
* @author Karl Wallendszus
* @created 2023-09-06
*
* @param dsbase		Base dataset to which the new databse is to be appended.
* @param dsnew		New dataset to be appended to the base dataset.
* @param debugfl	Debug flag (Y/N).
********************************************************************************
*/
%macro append_addcols ( dsbase=, dsnew=, debugfl=N );

	%* Retrieve lists of columns in each dataset;
	proc contents data = &dsbase. out = contbase;
	proc contents data = &dsnew. out = contnew;
	proc sort data = contbase;
		by varnum;
	proc sort data = contnew;
		by varnum;
	run;

	%* Find any variables which are in the new and not the base dataset;
	%local nnewvars newvars newvartypes newvarlens varlist;
	proc sql;
		select count(*) into :nnewvars
			from contnew n left join contbase b on n.name = b.name
			where b.name is null;
		select n.name, n.type, n.length into 
				:newvars separated by ' ', :newvartypes separated by ' ',
				:newvarlens separated by ' '
			from contnew n left join contbase b on n.name = b.name
			where b.name is null
			order by 1;
		select name into :varlist separated by ' '
			from contnew
			order by varnum;
	quit;

	%* Make a working copy of the base dataset adding any new variables;
	data dswork;
		set &dsbase.;
		%if %eval(&nnewvars.) > 0 %then %do;
			%local ivar newvar newvartype newvarlen;
			%do ivar = 1 %to &nnewvars.;
				%let newvar = %scan(&newvars., &ivar., ' ');
				%let newvartype = %scan(&newvartypes., &ivar., ' ');
				%let newvarlen = %scan(&newvarlens., &ivar., ' ');
				%if &newvartype. = 1 %then %do;
					length &newvar. &newvarlen.;
				%end;
				%else %do;
					length &newvar. $&newvarlen.;
				%end;
			%end;
		%end;
	run;

	%* Append new to work dataset;
	proc append base = dswork data = &dsnew.;
	run;
	quit;

	%* Copy work to base dataset using retain to preserve variable order;
	data &dsbase.;
		retain &varlist.;
		set dswork;
	run;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete contbase contnew dswork;
		run;
		quit;
	%end;

%mend append_addcols;

*******************************************************************************;
