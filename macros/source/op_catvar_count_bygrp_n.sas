/*!
********************************************************************************
* Execute an analysis operation:
* Operation ID:		Mth01_CatVar_Count_ByGrp_1_n
* Operation name:	Count of subjects
*
* @param analid			Analysis ID.
* @param methid			Method ID.
* @param opid			Operation ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param dsin			Input analysis dataset.
* @param dsout			Output analysis results dataset.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro op_catvar_count_bygrp_n ( analid=, methid=, opid=, groupingids=, dsin=, 
	dsout=, debugfl=N );

	* Build the tables request;
	%local igrouping ngroupings groupingid tabreq;
	%let igrouping = 1;
	%do %while (%scan(&groupingids., &igrouping., '|') ne );
		%let groupingid = %scan(&groupingids., &igrouping., '|');
		%local groupingid&igrouping.;
		%let groupingid&igrouping. = &groupingid.;
		%if &igrouping. eq 1 %then %do;
			%let tabreq = &groupingid.;
		%end;
		%else %do;
			%let tabreq = &tabreq. * &groupingid.;
		%end;
		%let igrouping = %eval(&igrouping.+1);
	%end;
	%let ngroupings = %eval(&igrouping.-1)

	%* Run the analysis;
	%if %sysfunc(exist(rawres)) %then %do;
		proc datasets library=work;
			delete rawres;
		run;
		quit;
	%end;
	proc freq data = &dsin.;
		tables &tabreq. / out = rawres;
	run;
	%if not %sysfunc(exist(rawres)) %then %do;
		data rawres;
			length NLevels 8;
			NLevels = 0;
		run;
	%end;

	%* Update the ARD from the raw results dataset;
	proc sql;
		update &dsout. as a
			set rawValue = ( 
				select r.count 
					from rawres as r
					where
					%do igrouping = 1 %to &&ngroupings;
						%if &igrouping. gt 1 %then %do;
						and 
						%end;
						a.resultGroup&igrouping._groupId = r.&&groupingid&igrouping.
					%end;
					)
				where a.analysisId = "&analid." and a.methodId = "&methid." and
					a.operationId = "&opid.";
	quit;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete rawres;
		run;
		quit;
	%end;

%mend op_catvar_count_bygrp_n;

*******************************************************************************;
