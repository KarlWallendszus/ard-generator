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
* @param analsetid		Analysis set ID.
* @param datasubsetid	Data subset ID.
* @param analds			Analysis dataset.
* @param analvar		Analysis variable.
* @param groupingids	List of pipe-delimited data grouping IDs.
* @param methid			Method ID.
* @param dsin			Input dataset containing the data to be analysed.
* @param dsout			Output dataset: outline ARD.
* @param debugfl		Debug flag (Y/N).
********************************************************************************
*/
%macro outline_ard ( ardlib=, mdlib=, analid=, groupingids=, dsin=, dsout=, 
	debugfl=N );

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
				where a.id = "&analid.";
	quit;

	/*
	%* If there are groupings, create an ARD fragment for them;
	%local ngroupings;
	%let ngroupings = 0;
	%if "&groupingids." ne %str() %then %do;
		%local igrouping;
		%let igrouping = 1;
		data ard_groupings;
			set ardwork;
		%do %while (%scan(&groupingids., &igrouping., '|') ne );
			length resultGroup&igrouping._groupingId $32
				resultGroup&igrouping._groupId $32
				resultGroup&igrouping._groupLabel $40
				resultGroup&igrouping._groupValue $80;
			%let igrouping = %eval(&igrouping.+1);
		%end;
		%let ngroupings = %eval(&igrouping.-1);
		run;
	%end;
	*/

	%* Create an empty ARD fragment for values;
	proc sql;
		create table ard_value (
			rawValue integer,
			formattedValue varchar(32) );
	quit;

	/*
	%* Insert a row for each expected result;
	proc sql;
		insert into &dsout.
			( id, analysisSet_label, method_id, method_label, 
				operation_id, operation_label, operation_resultPattern, 
				resultGroup1_groupingId, resultGroup1_groupId, 
				resultGroup1_group_label, 
				resultGroup2_groupingId, resultGroup2_groupId, 
				resultGroup2_group_label, 
				resultGroup3_groupingId, resultGroup3_groupId, 
				resultGroup3_group_label )
			select a.id, s.label, a.method_id, m.label, m.operation_id, 
					m.operation_label, m.operation_resultPattern, 
					g1.grouping_id, g1.groupValue, g1.groupLabel,
					g2.grouping_id, g2.groupValue, g2.groupLabel,
					g3.grouping_id, g3.groupValue, g3.groupLabel
				from &mdlib..analyses a join &mdlib..analysissets s 
					on a.analysisSetId = s.id
					join &mdlib..analysismethods m on a.method_id = m.id
					left join &dsvals. g1 on a.groupingId1 = g1.grouping_id
					left join &dsvals. g2 on a.groupingId2 = g2.grouping_id
					left join &dsvals. g3 on a.groupingId3 = g3.grouping_id
				where a.id = "&analid." and a.method_id = "&methid." and 
					m.operation_id = "&opid.";
	quit;
	*/

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		/*
		proc datasets library=work;
			delete ardwork;
		run;
		quit;
		*/
	%end;

%mend outline_ard;

*******************************************************************************;
