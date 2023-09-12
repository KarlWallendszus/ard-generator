/*!
********************************************************************************
* Execute an analysis operation:
* Operation ID:		Mth01_CatVar_Summ_ByGrp_2_pct
* Operation name:	Percentage of subjects
*
* @param analid			Analysis ID.
* @param methid			Method ID.
* @param opid			Operation ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param num_analid		Analysis ID for numerator.
* @param num_opid		operation ID for numerator.
* @param den_analid		Analysis ID for denominator.
* @param dem_opid		operation ID for denominator.
* @param ardin			Input analysis results dataset.
* @param dsout			Output analysis results dataset.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro op_catvar_summ_bygrp_pct ( analid=, methid=, opid=, groupingids=, 
	num_analid=, num_opid=, den_analid=, den_opid=, ardin=, dsout=, debugfl=N );

	%* Parse the groupings;
	%local igrouping ngroupings groupingid;
	%let igrouping = 1;
	%do %while (%scan(&groupingids., &igrouping., '|') ne );
		%let groupingid = %scan(&groupingids., &igrouping., '|');
		%local groupingid&igrouping.;
		%let groupingid&igrouping. = &groupingid.;
		%let igrouping = %eval(&igrouping.+1);
	%end;
	%let ngroupings = %eval(&igrouping.-1);

	%* Get numerators;
	data numstats;
		set &ardin. (
			keep = analysisid operationid
			%do igrouping = 1 %to &ngroupings.;
				resultgroup&igrouping._groupid
			%end;
				rawvalue
			where = ( analysisid = "&num_analid." and operationid = "&num_opid." ) );
	run;
	proc sort data = numstats;
		by 
		%do igrouping = 1 %to &ngroupings.;
			resultgroup&igrouping._groupid
		%end;
		;
	run;

	%* Get denominators;
	data denstats;
		set &ardin. (
			keep = analysisid operationid
			%do igrouping = 1 %to &ngroupings.;
				resultgroup&igrouping._groupid
			%end;
				rawvalue
			where = ( analysisid = "&den_analid." and operationid = "&den_opid." ) );
	run;
	proc sort data = denstats;
		by 
		%do igrouping = 1 %to &ngroupings.;
			resultgroup&igrouping._groupid
		%end;
		;
	run;

	%* Denominators may not use all the groupings that numerator do so work out 
	which ones are used;
	%do igrouping = 1 %to &ngroupings.;
		%local dengroupingcount&igrouping. dengroupingflag&igrouping.;
		proc sql;
			select count(*) into :dengroupingcount&igrouping.
				from denstats
				where resultgroup&igrouping._groupid is not null;
			quit;
			%if %eval(&&dengroupingcount&igrouping.) > 0 
				%then %let dengroupingflag&igrouping. = Y;
			%else %let dengroupingflag&igrouping. = N;
		quit;
	%end;

	%* Combine numerators and denominators;
	%local firstcond;
	%let firstcond = Y;
	proc sql;
		create table pctstats
			as select 
				%do igrouping = 1 %to &ngroupings.;
					n.resultgroup&igrouping._groupid,
				%end;
				n.rawvalue as numvalue, d.rawvalue as denvalue
				from numstats n left join denstats d on
				%do igrouping = 1 %to &ngroupings.;
					%if &&dengroupingflag&igrouping. = Y %then %do;
						%if &firstcond. = Y %then %do;
							%let firstcond = N;
						%end;
						%else %do;
							and
						%end;
						n.resultgroup&igrouping._groupid = d.resultgroup&igrouping._groupid
					%end;
				%end;
				;
	quit;

	* Calculate percentages;
	data pctstats;
		set pctstats;
		length pctvalue 8;
		pctvalue = numvalue * 100.0 / denvalue;
	run;

	%* Update the ARD from the raw results dataset;
	proc sql;
		update &dsout. as a
			set rawValue = ( 
				select r.pctvalue 
					from pctstats as r
					where
					%do igrouping = 1 %to &&ngroupings;
						%if &igrouping. gt 1 %then %do;
						and 
						%end;
						a.resultGroup&igrouping._groupId = r.resultGroup&igrouping._groupId
					%end;
					)
				where a.analysisId = "&analid." and a.methodId = "&methid." and
					a.operationId = "&opid.";
	quit;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete denstats numstats pctstats;
		run;
		quit;
	%end;

%mend op_catvar_summ_bygrp_pct;

*******************************************************************************;
