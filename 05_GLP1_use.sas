/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 
| Date (update): June 2025
| Task Purpose : 
|    
| Main dataset : (1) min.bs_glp1_user_v03
************************************************************************************/


/************************************************************************************
	STEP 1. Analysis of glp1 initiation only for GLP-1 initiaters (n=6335)
************************************************************************************/

/**************************************************
* new dataset: min.glp1_users_6335
* original dataset: min.bs_glp1_user_v03 (N = 37643)
* description: 
**************************************************/

data min.glp1_users_13268;
  set min.bs_glp1_user_v03;
  if temporality = 2;
run; /* 13268 obs */

proc means data=min.glp1_users_13268
  n nmiss mean std min max median p25 p75;
  var gap_glp1_bs;
  title "distribution of time to post-surgery GLP-1 use";
run;

/************************************************************************************
	STEP 2. Analysis of glp1 initiation by glp1 types - calendar time
************************************************************************************/

/**************************
	figure 3
 
 * xaxis:'calender year' 
 * excl. exenatide, lixi, missing
 * added table with number under the graph
 
**************************/

/**************************************************
* new dataset: min.glp1_users_6335_v01
* original dataset: min.glp1_users_6335
* description: add 'total' colunm by time_to_ini_cat
**************************************************/

* add calender year;
data min.glp1_users_13268_v01;
	set min.glp1_users_13268;
 	format glp1_init_year 4.;
	glp1_init_year = year(glp1_initiation_date);
run;
proc print data=min.glp1_users_13268_v01 (obs=30);
	var patient_id glp1_initiation_date glp1_init_year ;
	where glp1_user =1;
run;

/* plotting purpose */
proc freq data=min.glp1_users_13268_v01 noprint;
    tables Molecule*glp1_init_year / out=min.glp1_users_13268_v01_pct;
run;

proc sql;
    create table min.glp1_user_linegraph as
    select Molecule,
           glp1_init_year,
           count, 
           percent, 
           100 * count / sum(count) as col_pct  
    from min.glp1_users_13268_v01_pct
    group by glp1_init_year;
quit;
proc print data=min.glp1_user_linegraph (obs=30);
	title "min.glp1_user_linegraph";
run;

/* add 'total' colunm by time_to_ini_cat */
/**************************************************
* new dataset: min.glp1_user_linegraph_v01
* original dataset: min.glp1_user_linegraph 
* description: add 'total' colunm by time_to_ini_cat
**************************************************/

data min.glp1_user_linegraph_v01;
    set min.glp1_user_linegraph;
    format total 8.;

    /* Calculate total count for each time_to_init_cat */
    by glp1_init_year;
    if first.glp1_init_year then total = 0; 
    total + count; 

    /* Output only the last record for each time_to_init_cat */
    if last.glp1_init_year then output; 
run;

/* merge */
data min.glp1_user_linegraph_v02;
    merge min.glp1_user_linegraph (in=indata)
          min.glp1_user_linegraph_v01 (in=totaldata keep=glp1_init_year total);
    by glp1_init_year;
run;
proc print data=min.glp1_user_linegraph_v02 (obs=30);
run;

/* line graph */
proc sgplot data=min.glp1_user_linegraph_v02;
	where Molecule in ('Semaglutide', 'Dulaglutide', 'Liraglutide', 'Tirzepatide'); /* Filter for specific Molecule values */
    scatter x=glp1_init_year y=col_pct / group=Molecule
                                           markerattrs=(symbol=circlefilled size=7)  /* Customize marker appearance */
                                           datalabel=col_pct datalabelattrs=(size=8); /* Add data labels */
    series x=glp1_init_year y=col_pct / group=Molecule lineattrs=(thickness=2);

    xaxis label="Calender Year" 
           valueattrs=(weight=bold size=10) /* Adjust label style */
           ;

    yaxis label="Percentage of GLP-1 initiation (%)" values=(0 to 80 by 10);
    title "GLP-1 Initiation Year by GLP-1 Type";
    xaxistable count / class=Molecule title = "Number of initiators by GLP1 types";
run;

/* total number */
proc freq data=min.glp1_user_linegraph_v01;
	table total*glp1_init_year;
run;


/************************************************************************************
	STEP 3. Make time-to-initiation variable 
************************************************************************************/

data min.glp1_users_13268_v02;
    set min.glp1_users_13268_v01;
    format time_to_glp1_cat 8.;
    
    /* Calculate the time difference in days */
    time_diff = glp1_initiation_date - bs_date;

    /* Categorize based on time difference */
    if 0 <= time_diff < 365 then time_to_glp1_cat = 1;        /* started within 1 year */
    else if 365 <= time_diff < 730 then time_to_glp1_cat = 2; /* started between 1-2 years */
    else if 730 <= time_diff < 1095 then time_to_glp1_cat = 3; /* started between 2-3 years */
    else if 1095 <= time_diff < 1460 then time_to_glp1_cat = 4; /* started between 3-4 years */
    else if 1460 <= time_diff < 1825 then time_to_glp1_cat = 5; /* started between 4-5 years */
    else if 1825 <= time_diff < 2190 then time_to_glp1_cat = 6; /* started between 5-6 years */
    else if 2190 <= time_diff < 2555 then time_to_glp1_cat = 7; /* started between 6-7 years */
    else if time_diff >= 2555 then time_to_glp1_cat = 8;       /* started after 7 years */

    drop time_diff;
run;
