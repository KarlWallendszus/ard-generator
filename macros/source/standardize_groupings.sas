/*!
* Standardize data according to a given list of groupings.
* Assumes all the relevant variables are in the input dataset.
* @author Karl Wallendszus
* @created 2023-08-29
*/
*******************************************************************************;
/**
* Standardize data according to a given list of groupings.
* Takes the grouping definition and creates an output dataset containing 
* everything in the input dataset and a new group variable with values 
* corresponding to the defined groups.
* This makes it possible to use statistical procedures on the data even where
* the group definitions are complex, e.g. where multiple raw values are 
* combined into a single group.
* Uses the method described in GitLab issue #89 comment 
* https://github.com/cdisc-org/analysis-results-standard/issues/89#issuecomment-1551619391
*
* @param dsgrp		Input dataset containing group definitions.
* @param dsexpr		Dataset containing associated expressions.
* @param dsin		Input dataset containing data to be grouped.
* @param ids		List of grouping IDs separated by '|'.
* @param dsout		Output dataset (working dataset with groupings applied).
* @param debugfl	Debug flag (Y/N).
*/
%macro standardize_groupings ( dsgrp=, dsexpr=, dsin=, ids=, dsout=, debugfl=N );

	* Create dataset for values of data-driven groupings;
	data groupvalues;
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
			%let dsgrpcond = &dsin.;
			proc sql;
				select count(distinct &&var&igrouping.) into :ngroups&igrouping.
					from &dsin.;
				insert into groupvalues
					( grouping_id, groupValue, groupLabel )
					select distinct "&&id&igrouping.", &&var&igrouping., 
							propcase(&&var&igrouping.)
						from &dsin.;
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
				insert into groupvalues
					( grouping_id, groupValue, groupLabel )
					select distinct id, group_id, group_label
						from &dsgrp.
						where id = "&&id&igrouping.";
			quit;
		%end;

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

	* Create working dataset;
	proc sql;
		create table dsout as
			select a.*
			%do igrouping = 1 %to &&ngroupings;
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
			from &dsin. a;
	quit;

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
		set dsout;
		%do igrouping = 1 %to &&ngroupings;
			label &&id&igrouping. = "%sysfunc(kstrip(&&label&igrouping.))";
			%if &&dd&igrouping. = FALSE %then %do;
				format &&id&igrouping. $&&id&igrouping...;
			%end;
		%end;
	run;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete dsout groupvalues;
		run;
		quit;
	%end;

%mend standardize_groupings;

*******************************************************************************;
