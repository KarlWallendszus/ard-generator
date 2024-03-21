/*!
********************************************************************************
* Execute an analysis operation:
* Operation ID:		Mth03_CatVar_Comp_PChiSq_1_pval
* Operation name:	P-value
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
%macro op_catvar_comp_pchisq_pval ( analid=, methid=, opid=, groupingids=, 
	dsin=, dsout=, debugfl=N );

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
		tables &tabreq. / chisq;
		output out = rawres chisq pchi;
	run;

	* Check that there is only 1 row in the outline ARD and the raw results;
	%local nobs_ard nobs_raw;
	data _null_;
		set &dsout. nobs = nobs;
		call symput('nobs_ard', nobs);
	run;
	data _null_;
		set rawres nobs = nobs;
		call symput('nobs_raw', nobs);
	run;
	%if &nobs_ard. ^= 1 %then 
		%put ERROR: &nobs_ard. rows in outline ARD (expecting 1);
	%if &nobs_raw. ^= 1 %then 
		%put ERROR: &nobs_raw. rows of raw results (expecting 1);

	%* Update the ARD from the raw results dataset;
	proc sql;
		update &dsout.
			set rawValue = ( 
				select p_pchi 
					from rawres );
	quit;

	/*
	%* Convert any missing results to zero;
	data &dsout.;
		set &dsout.;
		if rawValue = . then rawValue = 0;
	run;
	*/

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete rawres;
		run;
		quit;
	%end;

%mend op_catvar_comp_pchisq_pval;

*******************************************************************************;
