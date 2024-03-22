/*!
********************************************************************************
* Execute one of the following analysis operations according to the oplabel 
* argument:
*
* oplabel
* chisq		Operation ID:	Mth03_CatVar_Comp_PChiSq_1_chisq
* 			Operation name:	Chi-squared
*
* df		Operation ID:	Mth03_CatVar_Comp_PChiSq_2_df
* 			Operation name:	Degrees of freedom
*
* p-value	Operation ID:	Mth03_CatVar_Comp_PChiSq_3_pval
* 			Operation name:	P-value
*
* The same PROC FREQ call is used for all of these operations; the difference
* is just which statistic is retrieved into the ARD. The mode argument 
* determines whether or not the procedure call is executed anew for the current
* operation. The mode argument can take the following values:
*   GEN	Results are generated anew by PROC FREQ (default)
*	RET	Results are simply retrieved from the raw results dataset which is 
*		assumed to already exist.
*	DEL	Results are retrieved from the raw results dataset which is then deleted.
* Therefore the most efficient way of calling this macro is to use GEN mode for
* the first call for a particular analysis, and RET mode for subsequent calls
* for that analysis, until the final call for the analysis where DEL mode is
* used.
*
* @param analid			Analysis ID.
* @param methid			Method ID.
* @param opid			Operation ID.
* @param oplabel		Operation label.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param mode			Mode: GEN, RET, DEL (see above)
* @param dsin			Input analysis dataset.
* @param dsout			Output analysis results dataset.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro op_catvar_comp_pchisq ( analid=, methid=, opid=, oplabel=,
	groupingids=, mode=GEN, dsin=, dsout=, debugfl=N );

	%* Build the tables request;
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
	%let ngroupings = %eval(&igrouping.-1);

	%* Run the analysis;
	%if &mode. = GEN %then %do;
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
	%end;

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

	%* Set the result column to use;
	%local rescol;
	%if %bquote(&oplabel.) = chisq %then %let rescol = _PCHI_;
	%else %if %bquote(&oplabel.) = df %then %let rescol = DF_PCHI;
	%else %if %bquote(&oplabel.) = %str(p-value) %then %let rescol = P_PCHI;

	%* Update the ARD from the raw results dataset;
	proc sql;
		update &dsout.
			set rawValue = ( 
				select &rescol. 
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
		%if &mode. = DEL %then %do;
			proc datasets library=work;
				delete rawres;
			run;
			quit;
		%end;
	%end;

%mend op_catvar_comp_pchisq;

*******************************************************************************;
