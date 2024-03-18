/*!
********************************************************************************
* Execute one of the following analysis operations according to the opstat 
* argument:
*
* oplabel
* N			Operation ID:	Mth02_ContVar_Summ_ByGrp_1_n
* 			Operation name:	Count of non-missing values
*
* Mean		Operation ID:	Mth02_ContVar_Summ_ByGrp_2_Mean
* 			Operation name:	Mean
*
* SD		Operation ID:	Mth02_ContVar_Summ_ByGrp_3_SD
* 			Operation name:	Standard deviation
*
* Median	Operation ID:	Mth02_ContVar_Summ_ByGrp_4_Median
* 			Operation name:	Median
*
* Q1		Operation ID:	Mth02_ContVar_Summ_ByGrp_5_Q1
* 			Operation name:	First quartile
*
* Q3		Operation ID:	Mth02_ContVar_Summ_ByGrp_6_Q3
* 			Operation name:	Third quartile
*
* Min		Operation ID:	Mth02_ContVar_Summ_ByGrp_7_Min
* 			Operation name:	Minimum
*
* Max		Operation ID:	Mth02_ContVar_Summ_ByGrp_8_Max
* 			Operation name:	Maximum
*
* The same PROC MEANS call is used for all of these operations; the difference
* is just which statistic is retrieved into the ARD. The mode argument 
* determines whether or not the procedure call is executed anew for the current
* operation. The mode argument can take the following values:
*   GEN	Results are generated anew by PROC MEANS (default)
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
* @param analvar		Analysis variable.
* @param dsout			Output analysis results dataset.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro op_contvar_summ_bygrp ( analid=, methid=, opid=, oplabel=, groupingids=, 
	mode=GEN, dsin=, analvar=, dsout=, debugfl=N );

	%* Parse the groupings;
	%local igrouping ngroupings groupingid groupinglist;
	%let groupinglist = %str();
	%let igrouping = 1;
	%do %while (%scan(&groupingids., &igrouping., '|') ne );
		%let groupingid = %scan(&groupingids., &igrouping., '|');
		%local groupingid&igrouping.;
		%let groupingid&igrouping. = &groupingid.;
		%let groupinglist = &groupinglist. &groupingid.;
		%let igrouping = %eval(&igrouping.+1);
	%end;
	%let ngroupings = %eval(&igrouping.-1);

	%* Calculate statistics;
	%if &mode. = GEN %then %do;
		proc sort data = &dsin.;
			by &groupinglist.;
		proc means data = &dsin. n mean stddev median q1 q3 min max;
			var &analvar.;
			output out=rawres 
				n=n mean=mean stddev=sd median=median q1=q1 q3=q3 min=min max=max;
			by &groupinglist.;
		run;
	%end;

	%* Update the ARD from the raw results dataset;
	proc sql;
		update &dsout. as a
			set rawValue = ( 
				select r.&oplabel.
					from rawres as r
					where
					%do igrouping = 1 %to &&ngroupings;
						%if &igrouping. gt 1 %then %do;
						and 
						%end;
						a.resultGroup&igrouping._groupvalue = r.&&groupingid&igrouping.
					%end;
					)
				where a.analysisId = "&analid." and a.methodId = "&methid." and
					a.operationId = "&opid.";
	quit;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		%if &mode. = DEL %then %do;
			proc datasets library=work;
				delete rawres;
			run;
			quit;
		%end;
	%end;

%mend op_contvar_summ_bygrp;

*******************************************************************************;
