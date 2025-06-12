/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 02_Cohort_dertivation_bs+demo+glp1
| Date (update): 
| Task Purpose : 
|      1. All glp1 users (regardless of BS history) (N = 1,088,256)
|      2. Among BS users, identify glp1 users     (among N = 42,535, glp1 users = 9,410)
|      3. Indicate the timing of glp1 use compared with the bs_date
| Main dataset : (1) min.bs_user_all_v07, (2) tx.medication_ingredient, (3) tx.medication_drug (adding quantity_dispensed + days_supply)
| Final dataset : min.bs_glp1_user_v03 (with duplicated indiv)
		  min.bs_glp1_user_38384_v00;

************************************************************************************/


/**************************************************
              Variable Definition
* table: min.bs_glp1_user_v03
* temporality
*       0  : no glp1_user   (n = 31667)
*       1  : take glp1 before BS   (n = 5863)
*       2  : take glp1 after BS    (n = 6466)
**************************************************/


/************************************************************************************
	STEP 1. All Glp1 users (regardless of BS history, age, index date)      N = 1,088,256
************************************************************************************/

* 0.0. explore original dataset;

proc print data=tx.medication_ingredient (obs=40); run;
proc contents data=tx.medication_ingredient; run;
proc print data=tx.medication_drug (obs=40); run;
proc contents data=tx.medication_drug; run;

/**************************************************
* new dataset: m.medication_ing_codelist
*              m.medication_drug_codelist
* original dataset: tx.medication_ingredient
* description: listup distinct value of the code_system variable
**************************************************/

* 1.0. check code_system to have distinct value of the code_system variable;

proc sql;
  create table m.medication_ing_codelist as
  select distinct code_system
  from tx.medication_ingredient; 
quit; 
proc print data=m.medication_ing_codelist; run;    /* 1 obs - only RxNorm */

proc sql;
  create table m.medication_drug_codelist as
  select distinct code_system
  from tx.medication_drug;
quit;                           /* 2 obs - NCD and RxNorm */
proc print data=m.medication_drug_codelist; run;

/*
	medication_ingredient | code system | RxNorm
	medication_drug | code system | RxNorm & NCD
*/


* 1.1. explore dataset to select glp1_users;

/*
glp1 only for obesity: Semaglutide [1991302] | Liraglutide [475968] | Tirzepatide [2601723]
  1) Semaglutide [1991302];
  2) Dulaglutide [1551291];
  3) Liraglutide [475968];
  4) Exenatide [60548];
  5) Lixisenatide [1440051];
  6) Tirzepatide [2601723];
*/


* 1.2. select "all" glp1_users;
*      sort by patient_id start_date Molecule to see individual's glp1 medication history;

/**************************************************
* new table: min.glp1_user_all
* original table: tx.medication_ingredient
* description: select "all" glp1_users from tx.medication_ingredient
**************************************************/

data min.glp1_user_all;
  set tx.medication_ingredient;
  where code in ("1991302", "1551291", "475968", "60548", "1440051", "2601723");
  if code = "1991302" then Molecule = "Semaglutide";
  else if code = "1551291" then Molecule = "Dulaglutide";
  else if code = "475968" then Molecule = "Liraglutide";
  else if code = "60548" then Molecule = "Exenatide";
  else if code = "1440051" then Molecule = "Lixisenatide";
  else if code = "2601723" then Molecule = "Tirzepatide";
run;                                                          /* 30,012,038 obs */

proc sort data = min.glp1_user_all;
  by patient_id start_date Molecule;
run;

* 1.3. add variable named 'Initiation_date' to indicate 'GLP1 initiation date by type of GLP1';
/**************************************************
* new table: min.glp1_user_all_initiation_date
* original table: min.glp1_user_all
* description: add variable named 'Initiation_date' to indicate 'GLP1 initiation date by type of GLP1'
**************************************************/

proc sql;
	create table min.glp1_user_all_initiation_date as
	select patient_id, min(start_date) as Initiation_date
	from min.glp1_user_all
	group by patient_id;
quit;
proc print data=min.glp1_user_all_initiation_date (obs=30);
	title "min.glp1_user_all_initiation_date";
run;


* 1.5. do mapping Initiation_date with 'min.glp1_user_all' table by patient.id;
/**************************************************
* new table: min.glp1_user_all_date
* original table: min.glp1_user_all + min.glp1_user_all_initiation_date
* description: left join min.glp1_user_all & min.glp1_user_all_initiation_date
**************************************************/

proc sql;
  create table min.glp1_user_all_date as
  select distinct a.*, b.Initiation_date
  from min.glp1_user_all a left join min.glp1_user_all_initiation_date b 
  on a.patient_id=b.patient_id;
quit;

proc sort data=min.glp1_user_all_date;
	by patient_id start_date;
run;                    /* 30,012,038 obs */


* 1.6. format date;

data min.glp1_user_all_date_v01;
	set min.glp1_user_all_date;
	start_date_num = input(start_date, yymmdd8.);
	Initiation_date_num = input(Initiation_date, yymmdd8.);
	format start_date_num Initiation_date_num yymmdd10.;
	drop start_date Initiation_date;
    rename start_date_num = glp1_date Initiation_date_num = glp1_initiation_date;
run;

* 1.7. calculate the total number of glp1 users;

proc sql;
	select count(distinct patient_id) as distinct_patient_count
 	from min.glp1_user_all_date_v01;
quit;          /* 1,750,054 distinct glp1 users */



/************************************************************************************
	STEP 2. Among BS users, identify glp1 users       N = 9,410 -> 12,329
************************************************************************************/

* 2.0. before merging, make indicator variables for glp1 users;
data min.glp1_user_all_date_v01; set min.glp1_user_all_date_v01; glp1_user = 1; run;             /* 30,012,038 obs */


* 2.1. merge 'bs_users table' and 'glp1_users table'; 
/**************************************************
* new table: min.bs_glp1_user_v00
* original table: min.bs_user_all_v08 + min.glp1_user_all_date
* description: Among glp1 users, identify glp1 users - join two tables
**************************************************/

proc SQL;
	create table min.bs_glp1_user_v00 as
 	select distinct a.*, b.*
	from min.bs_user_all_v08 as a left join min.glp1_user_all_date_v01 as b 
	on a.patient_id=b.patient_id;
quit;       /* 539,004 obs */

* 2.2. fill '0' in glp1_user cells with null values for further analysis;
data min.bs_glp1_user_v00; set min.bs_glp1_user_v00; if missing(glp1_user) then glp1_user = '0'; run;

* 2.3. count the population number;
proc sql;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_glp1_user_v00;
quit;        /* 123,111 individuals */  

proc sql;
    select count(distinct patient_id) as distinct_patient_count
    from min.bs_glp1_user_v00
    where glp1_user = 1;
quit;       /* 25985 individuals (21.11 %) */



/************************************************************************************
	STEP 3. Indicate the timing order of glp1 use compared with the bs_date  
************************************************************************************/

* 3.1. calculate gap between glp1_initiation_date and the bs_date;
/**************************************************
* new table: min.bs_glp1_user_v02
*            min.bs_glp1_user_v01
* original table: min.bs_glp1_user_v00
* description: calculate gap between glp1_initiation_date and the bs_date;
**************************************************/

* make indicator;
data min.bs_glp1_user_v01;
	set min.bs_glp1_user_v00;
	gap_glp1_bs = glp1_initiation_date - bs_date;
run;      /* 539004 obs */

proc print data=min.bs_glp1_user_v01 (obs = 30);
	var patient_id glp1_user bs_date glp1_initiation_date glp1_date gap_glp1_bs;
 	where glp1_user = 1;
  	title "min.bs_glp1_user_v01";
run;

data min.bs_glp1_user_v01;
	set min.bs_glp1_user_v01;
    if glp1_user = 0 then temporality = 0;
    else if gap_glp1_bs < 0 then temporality = 1;
    else if gap_glp1_bs >= 0 then temporality = 2;
run;


* 3.2. Remove duplications (only remain 'the last glp1_date' & removing other glp1_date information;

/************************************************************************************
	STEP 4. Make distinct paitent_id                  (N = 123111)
************************************************************************************/

proc sort data = min.bs_glp1_user_v01; by patient_id glp1_date; run;

data min.bs_glp1_user_v02;
    set min.bs_glp1_user_v01;
    by patient_id; 
    if first.patient_id; 
run;     /* 123111 obs */


/************************************************************************************
	STEP 5. Remove People with death_date < GLP1_initiation_date            (N = 18)
************************************************************************************/

data min.bs_glp1_user_v03;
    set min.bs_glp1_user_v02;
    if not missing(death_date) and death_date < glp1_initiation_date then delete;
run;   /* 123,093 */


/************************************************************************************
	STEP 5. Remove the before use within one year before surgery            (N = 3049)
************************************************************************************/

proc freq data=min.bs_glp1_user_v03;
	table temporality;
run;
/**************************************************
              Variable Definition
* table: min.bs_glp1_user_v02
* temporality
*       0  : no glp1_user   (n = 97126)
*       1  : take glp1 before BS   (n = 10198)
*       2  : take glp1 after BS    (n = 15769)
**************************************************/

data min.bs_glp1_user_v03;
    set min.bs_glp1_user_v03;
    if temporality = 1 then delete;
run;      /* 82,212 obs */

proc print data=min.bs_glp1_user_v03 (obs=30); run;

/************************************************************************************
	min.bs_glp1_user_v03            (N = 82,212)
 *       0  : no glp1_user   (n = 68,944)
 *       2  : take glp1 after BS    (n = 13,268)
************************************************************************************/
