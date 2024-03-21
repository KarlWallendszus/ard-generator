/*!
********************************************************************************
* Creates an outline analysis results dataset containing a row for every
* expected result for the specified operation.
* The dataset is populated with metadata but no results data.
* @author Karl Wallendszus
* @created 2023-08-30
*
* @param ardlib			Library containing analysis results datasets.
* @param mdlib			Library containing metadata datasets.
* @param analid			Analysis ID.
* @param opid			Operation ID.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param dsin			Input dataset containing the data to be analysed.
* @param dsout			Output dataset: outline ARD.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro outline_ard ( ardlib=, mdlib=, analid=, opid=, groupingids=, dsin=, 
	dsout=, debugfl=N );

	%* Create an ARD fragment containing core metadata;
	%* One row per operation in this analysis;
	proc sql;
		create table ard_coremd (
			analysisId varchar(40),
			analysisName varchar(200), 
			analysisSetId varchar(40),
			analysisSetLabel varchar(200),
			dataSubsetId varchar(40),
			dataSubsetLabel varchar(200),
			analysisDataset varchar(32), 
			analysisVariable varchar(32),
			methodId varchar(40),
			methodName varchar(200),
			operationId varchar(40),
			operationName varchar(200) );
		insert into ard_coremd
			( analysisId, analysisName, analysisSetId, analysisSetLabel,
				dataSubsetId, dataSubsetLabel, 
				analysisDataset, analysisVariable, methodId, methodName, 
				operationId, operationName )
			select a.id, a.name, a.analysisSetId, s.label,
					a.dataSubsetId, d.label, a.dataset, a.variable, 
					a.method_id, m.name, o.operation_id, o.operation_name
				from &mdlib..analyses a 
					left join &mdlib..analysissets s on a.analysisSetId = s.id
					left join &mdlib..datasubsets d on a.analysisSetId = d.id
					left join &mdlib..analysismethods m on a.method_id = m.id
					left join &mdlib..methodoperations o on a.method_id = o.id
				where a.id = "&analid." and o.operation_id = "&opid.";
	quit;

	%* If there are groupings, process them;
	%local ngroupings;
	%let ngroupings = 0;
	%if "&groupingids." eq %str() %then %do;
		proc sql;
		   	create table ard_grouping (
				resultGroup1_groupingId varchar(40),
				resultGroup1_groupId varchar(40),
				resultGroup1_groupLabel varchar(40),
				resultGroup1_groupValue varchar(80) )
		quit;
	%end;
	%else %do;
		%local igrouping;

		%* Create an ARD fragment for groupings;
		%let igrouping = 1;
		proc sql;
		   	create table ard_grouping (
		%do %while (%scan(&groupingids., &igrouping., '|') ne );
			%if &igrouping. gt 1 %then %do;
				,
			%end;
			resultGroup&igrouping._groupingId varchar(40),
			resultGroup&igrouping._groupId varchar(40),
			resultGroup&igrouping._groupLabel varchar(40),
			resultGroup&igrouping._groupValue varchar(80)
			%let igrouping = %eval(&igrouping.+1);
		%end;
		 );
		quit;
		%let ngroupings = %eval(&igrouping.-1);

		* Create a dataset for each grouping containing its distinct values;
		%local groupingid resbygroup datadriven;
		%do igrouping = 1 %to &&ngroupings;
			%let groupingid = %scan(&groupingids., &igrouping., '|');
			proc sql;
				select resultsByGroup&igrouping. into :resbygroup
					from &mdlib..analyses
					where id = "&analid.";
				%if &resbygroup. = TRUE %then %do;
				* We want a result for each group;
					select datadriven into :datadriven
						from &mdlib..analysisgroupings
						where id = "&groupingid.";
					%if &datadriven. = TRUE %then %do;
						create table groupvalues&igrouping.
							as select distinct g.id as groupingid,
									g.group_id as groupid, 
									g.group_label as grouplabel,
									d.&groupingid. as groupvalue
								from &mdlib..analysisgroupings g, &dsin. d
								where g.id = "&groupingid."
								order by 1, 2, 4;
					%end;
					%else %do;
						create table groupvalues&igrouping.
							as select id as groupingid,
									group_id as groupid, 
									group_label as grouplabel,
									group_id as groupvalue
								from &mdlib..analysisgroupings
								where id = "&groupingid."
								order by 1, 2, 4;
					%end;
				%end;
				%else %do;
				* We want one result for the whole grouping;
					create table groupvalues&igrouping.
						as select groupingid&igrouping. as groupingid,
								'' as groupid, 
								'' as grouplabel,
								'' as groupvalue
							from &mdlib..analyses
							where id = "&analid.";
				%end;
			quit;
		%end;

		* Insert a row into the ARD fragment for each combination of groups;
		proc sql;
			insert into ard_grouping ( 
			%do igrouping = 1 %to &&ngroupings;
				%if &igrouping. gt 1 %then %do;
					,
				%end;
				resultGroup&igrouping._groupingId,
				resultGroup&igrouping._groupId,
				resultGroup&igrouping._groupLabel,
				resultGroup&igrouping._groupValue
			%end;
			)
			select 
			%do igrouping = 1 %to &&ngroupings;
				%if &igrouping. gt 1 %then %do;
					,
				%end;
				g&igrouping..groupingId, g&igrouping..groupId,
				g&igrouping..groupLabel, g&igrouping..groupValue
			%end;
			from 
			%do igrouping = 1 %to &&ngroupings;
				%if &igrouping. gt 1 %then %do;
					,
				%end;
				groupvalues&igrouping. g&igrouping.
			%end;
			;
		quit;
	%end;

	%* Create an empty ARD fragment for values;
	proc sql;
		create table ard_value (
			rawValue integer,
			formattedValue varchar(32) );
	quit;

	%* Joim all the ARD fragments together;
	proc sql;
		create table &dsout.
			as select c.*, g.*, v.*
				from ard_coremd c join ard_grouping g on 1=1
					left join ard_value v on 1=1;
	quit;

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		proc datasets library=work;
			delete ard_coremd ard_grouping ard_value
			%do igrouping = 1 %to &&ngroupings;
				groupvalues&igrouping.
			%end;
			;
		run;
		quit;
	%end;

%mend outline_ard;

*******************************************************************************;
