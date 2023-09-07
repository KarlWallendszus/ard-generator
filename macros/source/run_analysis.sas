/*!
********************************************************************************
* Run a single analysis.
* @author Karl Wallendszus
* @created 2023-07-31
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param ardlib		Library containing analysis results datasets.
* @param analid		Analysis ID.
* @param debugfl	Debug flag (Y/N).
********************************************************************************
*/
%macro run_analysis ( mdlib=, datalib=, ardlib=, analid=, debugfl=N );

	* Get analysis details;
	%local analname analdesc analver analreas analpurp analds analvar analsetid 
		datasubsetid methid
		ngroupings groupingords groupingids groupingresbys 
		nrefops refopords refoprelids refopanalids
		docrefs catids;
	proc sql;
		select name, description, version, reason, purpose, dataset, variable, 
					analysisSetId, dataSubsetId, method_id
				into :analname, :analdesc, :analver, :analreas, :analpurp, 
					:analds, :analvar, :analsetid, :datasubsetid, :methid
			from &mdlib..analyses
			where id = "&analid.";
		select count(*) into :ngroupings
			from &mdlib..analysesordgroupings
			where id = "&analid.";
		select order, groupingId, resultsByGroup
			into :groupingords separated by '|', :groupingids separated by '|', 
				:groupingresbys separated by '|'
			from &mdlib..analysesordgroupings
			where id = "&analid."
			order by 1;
		select count(*) into :nrefops
			from &mdlib..analysesrefoperations
			where id = "&analid.";
		select order, referencedOperationRelationshipI, analysisId
			into :refopords separated by '|', :refoprelids separated by '|', 
				:refopanalids separated by '|'
			from &mdlib..analysesrefoperations
			where id = "&analid."
			order by 1;
	quit;

	* Extract grouping details into separate macro variables;
	%local ig;
	%do ig = 1 %to &ngroupings.;
		%local groupingord&ig. groupingid&ig. groupingresby&ig.;
		%let groupingord&ig. = %scan(&groupingords., &ig., '|');
		%let groupingid&ig. = %scan(&groupingids., &ig., '|');
		%let groupingresby&ig. = %scan(&groupingresbys., &ig., '|');
	%end;

	* Extract referenced operaation details into separate macro variables;
	%local ir;
	%do ir = 1 %to &nrefops.;
		%local refopord&ir. refoprelid&ir. refopanalid&ir.;
		%let refopord&ir. = %scan(&refopords., &ir., '|');
		%let refoprelid&ir. = %scan(&refoprelids., &ir., '|');
		%let refopanalid&ir. = %scan(&refopanalids., &ir., '|');
	%end;

	* Show analysis details;
	%put NOTE: ================================================================================;
	%put NOTE: Analysis &analid.: &analname.;
	%put NOTE:   Description: &analdesc.;
	%put NOTE:   Version: &analver.;
	%put NOTE:   Reason: &analreas.;
	%put NOTE:   Purpose: &analpurp.;
	%put NOTE:   Dataset: &analds.;
	%put NOTE:   Variable: &analvar.;
	%put NOTE:   Analysis set: &analsetid.;
	%put NOTE:   Data subset: &datasubsetid.;
	%put NOTE:   Method: &methid.;
	%do ig = 1 %to &ngroupings.;
		%put NOTE:   Grouping &&groupingord&ig.: &&groupingid&ig. (result by group: &&groupingresby&ig.);
	%end;
	%do ir = 1 %to &nrefops.;
		%put NOTE:   Referenced operation &&refopord&ir.:;
		%put NOTE:     Relationship &&refoprelid&ir.;
		%put NOTE:     Analysis: &&refopanalid&ir.;
	%end;
	
	* Run the analysis method;
	%run_method(mdlib=&mdlib., datalib=&datalib., ardlib=&ardlib., 
		methid=&methid., analid=&analid., analsetid=&analsetid., 
		datasubsetid=&datasubsetid., analds=&analds., analvar=&analvar.,
		groupingids=&groupingids., debugfl=&debugfl.);

	* Tidy up unless in debug mode;
	%if &debugfl. = N %then %do;
		/*
		proc datasets library=work;
			delete adwork analset analysisresults grouping rawres;
		run;
		quit;
		*/
	%end;

	* Write completion message to log;
	%put NOTE: Analysis &analid. completed;
	%put NOTE: ================================================================================;

%mend run_analysis;

*******************************************************************************;
