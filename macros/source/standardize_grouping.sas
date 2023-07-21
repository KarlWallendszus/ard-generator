/*!
* Standardize data according to a given grouping.
* @author Karl Wallendszus
* @created 2023-07-21
*/
*******************************************************************************;
/**
* Standardize data according to a given grouping.
* Takes the grouping definition and creates an output dataset containing the 
* data to be grouped and a new group variable with values corresponding to the
* defined groups.
* This makes it possible to use statistical procedures on the data even where
* the group definitions are complex, e.g. where multiple raw values are 
* combined into a single group.
* Uses the method described in GitLab issue #89 comment 
* https://github.com/cdisc-org/analysis-results-standard/issues/89#issuecomment-1551619391
*
* @param dsgrp		Input dataset containing group definitions.
* @param dsexpr		Dataset containing associated expressions.
* @param datalib	Library containing data to be grouped.
* @param dsdd		Dataset to be used to determine data-driven groups.
* @param ids		List of grouping IDs separated by '|'.
* @param dsout		Output dataset (working dataset with groupings applied).
* @param dsvals		Output dataset containing values of groupings.
* @param debugfl	Debug flag (Y/N).
*/
%macro standardize_grouping ( dsgrp=, dsexpr=, datalib=, dsdd=, ids=, dsout=, 
	dsvals=groupvalues, debugfl=N );

	* Create dataset for names of datasets containing data to be grouped;
	data dsds;
		length groupingtype $8 dsname $32;
		stop;
	run;

	* Create dataset for values of data-driven groupings;
	%if %sysfunc(exist(&dsvals.)) %then %do;
		proc datasets library=work;
			delete &dsvals.;
		run;
		quit;
	%end;
	data &dsvals.;
		length grouping_id $32 groupValue groupLabel $200;
		stop;
	run;

	* Loop through groupings;
	%local igrouping ngroupings dsgrpcond gids glabels gexprs igroup;
	%let igrouping = 1;
	%do %while (%scan(&ids., &igrouping., '|') ne );
		%local type&igrouping. id&igrouping. label&igrouping. var&igrouping. 
			dd&igrouping.;
		%let id&igrouping = %scan(&ids., &igrouping., '|');

		* Get grouping details;
		proc sql;
			select distinct grouping_type, label, groupingVariable, dataDriven 
					into :type&igrouping., :label&igrouping., :var&igrouping., 
						:dd&igrouping.
				from &dsgrp.
				where id = "&&id&igrouping.";
		quit;

		* Get details of groups in this grouping;
		%local dsanal&igrouping. ngroups&igrouping.;
		%if &&dd&igrouping. = TRUE %then %do;
			%let dsgrpcond = &dsdd.;
			proc sql;
				select count(distinct &&var&igrouping.) into :ngroups&igrouping.
					from &datalib..&dsdd.;
				insert into &dsvals.
					( grouping_id, groupValue, groupLabel )
					select distinct "&&id&igrouping.", &&var&igrouping., 
							propcase(&&var&igrouping.)
						from &datalib..&dsdd.;
			quit;
		%end;
		%else %do;
			proc sql;
				select group_condition_dataset into :dsgrpcond
					from &dsgrp.
					where id = "&&id&igrouping.";
				select count(distinct group_id) into :ngroups&igrouping.
					from &dsgrp.
					where id = "&&id&igrouping.";
				select g.group_id, g.group_label, e.expression 
						into :gids separated by '|', :glabels separated by '|',
							:gexprs separated by '#'
					from &dsgrp. g join &dsexpr. e on g.group_id = e.id
					where g.id = "&&id&igrouping."
					order by g.order;
				insert into &dsvals.
					( grouping_id, groupValue, groupLabel )
					select distinct id, group_id, group_label
						from &dsgrp.
						where id = "&&id&igrouping.";
			quit;
		%end;

		* Insert dataset name into dsds;
		%let dsanal&igrouping. = &datalib..&dsgrpcond.;
		proc sql;
			insert into dsds
				( groupingtype, dsname )
				values ( "&&type&igrouping.", "&&dsanal&igrouping." );
		quit;

		* Loop through groups;
		%if &&dd&igrouping. = FALSE %then %do;
			%do igroup = 1 %to &&ngroups&igrouping.;
				%local gid&igrouping._&igroup. glabel&igrouping._&igroup. 
					gexpr&igrouping._&igroup.;
				%let gid&igrouping._&igroup. = %scan(&gids., &igroup., '|');
				%let glabel&igrouping._&igroup. = %scan(&glabels., &igroup., '|');
				%let gexpr&igrouping._&igroup. = %scan(&gexprs., &igroup., '#');
			%end;
		%end;

		%let igrouping = %eval(&igrouping.+1);
	%end;
	%let ngroupings = %eval(&igrouping.-1);

	* Show groupings and the groups in them;
	%do igrouping = 1 %to &&ngroupings;
		%put NOTE: Grouping &igrouping.: &&id&igrouping. (%sysfunc(kstrip(&&label&igrouping.)));
		%if &&dd&igrouping. = TRUE %then %do;
			%put NOTE:   Data-driven groups: %sysfunc(kstrip(&&ngroups&igrouping.)) groups found;
		%end;
		%else %do;
			%do igroup = 1 %to &&ngroups&igrouping.;
				%put NOTE:   Group &igroup.: &&gid&igrouping._&igroup. (%sysfunc(kstrip(&&glabel&igrouping._&igroup.)));
			%end;
		%end;
	%end;

	* Get list of distinct datasets;
	%local ndsnames dsnames idsn;
	proc sql;
		select count(distinct dsname) into :ndsnames
			from dsds;
		select distinct dsname into :dsnames separated by '|'
			from dsds;
	quit;

	* Create working dataset or each input dataset;
	%let idsn = 1;
	%do idsn = 1 %to &ndsnames.;
		%local dsname&idsn.;
		%let dsname&idsn. = %scan(&dsnames., &idsn., '|');
		proc sql;
			create table dsout&idsn. as
				select a.*
				%do igrouping = 1 %to &&ngroupings;
					%if &&dsanal&igrouping. = &&dsname&idsn. %then %do;
						%if &&dd&igrouping. = TRUE %then %do;
							, a.&&var&igrouping. as &&id&igrouping.
						%end;
						%else %do;
							, case
							%do igroup = 1 %to &&ngroups&igrouping.;
								when &&gexpr&igrouping._&igroup. then "&&gid&igrouping._&igroup."
							%end;
							end as &&id&igrouping.
						%end;
					%end;
				%end;
				from &&dsname&idsn. a;
		quit;
	%end;

	* Define formats for group values;
	%do igrouping = 1 %to &&ngroupings;
		%if &&dd&igrouping. = FALSE %then %do;
			proc format;
				value $&&id&igrouping.
				%do igroup = 1 %to &&ngroups&igrouping.;
					"&&gid&igrouping._&igroup." = "%sysfunc(kstrip(&&glabel&igrouping._&igroup.))"
				%end;
				;
			run;
		%end;
	%end;

	* Create output dataset from working versions;
	data &dsout.;
		%if &ndsnames. = 1 %then %do;
			set dsout1;
		%end;
		%else %do;
			merge
			%do idsn = 1 %to &ndsnames.;
				dsout&idsn.
			%end; 
			;
			by usubjid;
		%end;
		%do igrouping = 1 %to &&ngroupings;
			label &&id&igrouping. = "%sysfunc(kstrip(&&label&igrouping.))";
			%if &&dd&igrouping. = FALSE %then %do;
				format &&id&igrouping. $&&id&igrouping...;
			%end;
		%end;
	run;

	* Sort the group values dataset;
	proc sort data = &dsvals.;
		by grouping_id groupValue;
	run;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete dsds
			%do idsn = 1 %to &ndsnames.;
				dsout&idsn.
			%end; 
			;
		run;
		quit;
	%end;

%mend standardize_grouping;

*******************************************************************************;
