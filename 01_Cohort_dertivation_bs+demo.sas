/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 01_Cohort_dertivation
| Date (update): June 2024
| Task Purpose : 
|      1. select all Bariatric Surgery(BS) users from 100% data (N = 99,350)
|      2. BS users (initial use date) between 2016 - 2020    (N = 45,761)
|      3. Merge "BS users 2016 - 2020" + demographic data (N = 45,761)
|      4. select Age >= 18 (N = 44,959)
|      5. exclude individuals without sex information (N = 42,535)
| Main dataset : (1) procedure, (2) tx.patient, (3) tx.patient_cohort & tx.genomic (but not merged)
| Final dataset : min.bs_user_all_v07 (with distinct indiv)
************************************************************************************/


/************************************************************************************
	STEP 1. All Bariatric Surgery(BS) users	     N = 99,350
************************************************************************************/

* 1.0. explore procedure dataset;

proc print data=tx.procedure (obs=40);
    title "tx.procedure";
run;                      
proc contents data=tx.procedure;
    title "tx.procedure";
run;                /* 1,582,000,163 obs  */

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from tx.procedure;
  	title "the number of total population in tx.procedure";
quit;   /*  obs */



* 1.1. list up all of the value of code_system;

/**************************************************
* new table: min.procedure_codelist
* original table: tx.procedure
* description: select "all" BS_users from tx.procedure
**************************************************/

proc sql;
  create table min.procedure_codelist as
  select distinct code_system
  from tx.procedure; 
quit; 
proc print data=min.procedure_codelist; 
  title "min.procedure_codelist";
run;


* 1.2. Select all BS_users and categorize them by the type of BS;

/**************************************************
* new table: min.bs_user_rygb_v01
*	           min.bs_user_sg_v01
* original table: tx.procedure
* description: select each type of BS_users from tx.procedure
**************************************************/

* 1.2.1. RYGB users (n = 70266 obs);

data min.bs_user_rygb;
  set tx.procedure;
  length bs_type $8;     
  if code in ("43644", "43645", "43846", "43847", "43633", "43.7", "44.39", "44.38", "0D16078", "0D16479", "0D1647A", "0D164J9", "0D164JA", "0D164K9", "0D164KA", "0D164Z9", "0D164ZA", "0D164ZB") then do;
  	bs_type = "rygb";
  end;
  else delete;
run;              /* 173145 obs */


data min.bs_user_rygb_v01;  /* distinct patient-date */
	set min.bs_user_rygb (keep = patient_id date bs_type);
run;               
proc sort data = min.bs_user_rygb_v01 nodupkey out =min.bs_user_rygb_v02;
	by _all_;
run;                /* 87831 obs - it includes all of dates for individuals who have more than one date */              

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_rygb_v02;
  	title "the number of distinct RYGB users";
quit;   /* 86090 obs - it includes only distinct RYGB users list */


* 1.2.2. SG users (n = 39738 -> 42981 obs);

data min.bs_user_sg;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43842", "43843", "43775", "44.68", "44.69", "43.82", "43.89", "0DQ60ZZ", "0DB64ZZ", "0DB64Z3") then do;
  	bs_type = "sg";
  end;
  else delete;
run;             /* 234543 obs */

data min.bs_user_sg_v01;  /* distinct patient-date */
	set min.bs_user_sg (keep = patient_id date bs_type);
run;              
proc sort data = min.bs_user_sg_v01 nodupkey out =min.bs_user_sg_v02;
	by _all_;
run;                /* 124080 obs - it includes all of dates for individuals who have more than one date */
               

proc SQL;
	select count(distinct patient_id) as distinct_patient_count,
 	count(patient_id) as total_patient_count
 	from min.bs_user_sg_v02;
quit;         /* 121037 obs - it includes only distinct SG users list */

proc SQL;
	select count(distinct patient_id) as distinct_patient_count,
 	count(patient_id) as total_patient_count
 	from min.bs_user_rygb_v01;
quit;   

/* test */
proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from tx.procedure;
quit;  

proc SQL;
	select count(patient_id) as total_patient_count, 
 	count(distinct patient_id) as distinct_patient_count
 	from tx.procedure;
quit;  

* 1.3. Merge all datasets of each type of BS to have all BS users file;

/**************************************************
* new table: min.bs_user_all_v00
		min.bs_user_all_v01
* original table: = min.bs_user_rygb_v02 + min.bs_user_sg_v02
* description: select "all" BS_users
**************************************************/

data min.bs_user_all_v00;
	set min.bs_user_rygb_v02 min.bs_user_sg_v02;
run;                          
proc sort data=min.bs_user_all_v00;
	by patient_id date;
run;                    /* 211911 obs */


/* to count distinct number of BS users */
proc SQL;
	select count(distinct patient_id) as distinct_patient_count,
 	count(patient_id) as total_patient_count
 	from min.bs_user_all_v00;
quit;        /* 199661 obs */


* 1.4. make variable "bs_count" indicating the number of BS by patient;
proc sql;
    create table min.bs_user_all_v00 as
    select *, count(*) as bs_count
    from min.bs_user_all_v00
    group by patient_id;
quit;

* 1.5. select the first BS date if patients have multiple BS (n = 81008) ;
proc sort data=min.bs_user_all_v00; by patient_id date; run;             
data min.bs_user_all_v01;
	set min.bs_user_all_v00;
	by patient_id;
	if first.patient_id;
run;           /* 199661 obs */


* 1.6. count how many individuals have multiple BS procedures;
proc freq data=min.bs_user_all_v01;
	table bs_count;
 	title "frequency distribution of bs_count";
run;


* 1.7. format date;
data min.bs_user_all_v01;
	set min.bs_user_all_v01;
	bs_date = input(date, yymmdd8.);
	format bs_date yymmdd10.;
	drop date;
run;
proc contents data=min.bs_user_all_v01;
	title "min.bs_user_all_v01";
run;


* 1.8. frequency distribution of users by BS type and count;
proc freq data=min.bs_user_all_v01;
	table bs_type;
 	title "frequency distribution of bs_type";
run;

proc freq data=min.bs_user_all_v01;
	table bs_count;
 	title "frequency distribution of bs_count";
run;

/************************************************************************************
	STEP 2. BS users (initial use date) between 2015 - 2021    N = 46711
************************************************************************************/

* 0. check the last date of procedure in the dataset;
data procedure;
	set tx.procedure;
	bs_date = input(date, yymmdd8.);
	format bs_date yymmdd10.;
	drop date;
run;
proc means data=procedure; var bs_date; run;  /* the last date of procedure in the original dataset is 25Jun25 */
proc means data=min.bs_user_all_v01; var bs_date; run;  /* the last date of procedure in potential study population is 14May25 */


* 2.1. select BS users between 2015 - 2021 ;

/**************************************************
* new table: min.bs_user_all_v02
* original table: min.bs_user_all_v01
* description: select BS users between 01JAN2015 - 31MAY2023
**************************************************/

data min.bs_user_all_v02;
	set min.bs_user_all_v01;
	where bs_date >= '01JAN2015'd and bs_date <= '31MAY2023'd;
run;   /* 110274 obs */

* 2.2. frequency distribution of users by BS type and count;

proc freq data=min.bs_user_all_v03;
	table bs_type;
 	title "frequency distribution of bs_type";
run;


/************************************************************************************
	STEP 3. Merge "BS users between 01JAN2015 - 31MAY2023" + "demographic data"       N = 110,274 -> 96,372
************************************************************************************/

* 3.0. see the demograph data;

proc print data=tx.patient (obs=40); title "tx.patient"; run;
proc contents data=tx.patient; title "tx.patient"; run;

proc print data=tx.patient_cohort (obs=40); title "tx.patient_cohort"; run;
proc contents data=tx.patient_cohort; title "tx.patient_cohort"; run;

proc print data=tx.genomic (obs=40); title "tx.genomic"; run;
proc contents data=tx.genomic; title "tx.genomic"; run;


* 3.1. Merge "BS users 2015 - 2023" + "demographic data";

/**************************************************
* new table: min.bs_user_all_v03
* original table: min.bs_user_all_v02 + tx.patient
* description: Merge "BS users 2015 - 2023" + "demographic data" 
**************************************************/     

proc sql;
  create table min.bs_user_all_v03 as
  select a.*, b.*
  from min.bs_user_all_v02 as a
  join tx.patient as b
  on a.patient_id = b.patient_id;
quit;   /* 130,744 obs */

proc freq data=min.bs_user_all_v03; table bs_type; run;


/* dropped individuals - patient_id */
/*
number of distinct patients
tx.procedure : 3,646,163
tx.patient : 3,872,624
(-) 226,461
*/
/*
proc sql;
  create table procedure_ids as
  select distinct patient_id
  from tx.procedure;
quit;

proc sql;
  create table notfound_ids as
  select a.*
  from procedure_ids as a
  left join tx.patient as b
  on a.patient_id = b.patient_id
  where b.patient_id is missing;
quit;

proc sql;
  create table notfound_ids as
  select a.*
  from procedure_ids as a
  inner join tx.patient as b
  on a.patient_id = b.patient_id;
quit;



proc sql;
  create table dropped_ids as
  select a.*
  from min.bs_user_all_v02 as a
  left join tx.patient as b
  on a.patient_id = b.patient_id
  where b.patient_id is missing;
quit;

proc print data=dropped_ids (obs=20); run;
*/


/************************************************************************************
	STEP 4. Age >= 18         N = 1894 (= 130744 - 128850 )
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v05
*             min.bs_user_all_v04
* original table: min.bs_user_all_v03
* description: "BS users 2016 - 2020" + age >= 18 
**************************************************/    

* 4.1. format date;
data min.bs_user_all_v04;
    set min.bs_user_all_v03;
	  year_of_birth_num = input(year_of_birth, $6.);
    format year_of_birth_num 6.;
    drop year_of_birth;
  rename year_of_birth_num = year_of_birth;
run; 

* 4.2. to convert 'year_of_birth' to 'age', change the format of the 'year_of_birth';
data min.bs_user_all_v04;
  set min.bs_user_all_v04;
  age_at_bs = year(bs_date) - year_of_birth;
run;

* 4.3. select individuals aged more than 18 years;
data min.bs_user_all_v05;
  set min.bs_user_all_v04;
  if age_at_bs >=18;
run;      /* 128850 obs */


/************************************************************************************
	STEP 5. Exclude individuals without sex      N = 0
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v06
* original table: min.bs_user_all_v05
* description: Exclude individuals without sex 
**************************************************/
proc freq data = min.bs_user_all_v05; table sex; run;                   /* nmiss in(sex) = 0 */

data min.bs_user_all_v06;	
	set min.bs_user_all_v05;
	if not missing (sex);
run;                   /* 128850 obs */


/************************************************************************************
	STEP 6. Exclude individuals outside the US       N = 4943
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v07
* original table: min.bs_user_all_v06
* description: Exclude individuals without sex 
**************************************************/

* postal_code: Diamond network : patient_regional_location;
proc freq data = min.bs_user_all_v06;
	table patient_regional_location;
run;               /* Ex-US = 957, Unknown = 4338 -> total = 5295 */ 

data min.bs_user_all_v07;	
	set min.bs_user_all_v06;
	if patient_regional_location in('Midwest', 'Northeast', 'South', 'West');
run;        /* 123,555 obs */


/************************************************************************************
	STEP 7. Exclude individual with invalid information (death < bs_date)      N = 463
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v08
* original table: min.bs_user_all_v07
* description: Exclude individual with invalid information (death < bs_date) 
**************************************************/
* convert death-date;
data min.bs_user_all_v08;
  set min.bs_user_all_v07;
  death_year = input(substr(month_year_death, 1, 4), 4.);
  death_month = input(substr(month_year_death, 5, 2), 2.);
  death_date = mdy(death_month,15,death_year);
  format death_date yymmdd10.;
run;

* delete the "not missing(death_date) and death_date < bs_date" individual;
data min.bs_user_all_v08;
    set min.bs_user_all_v08;
    if not missing(death_date) and death_date < bs_date then delete;
run;       /* 123,111 obs */

/************************************************************************************
	 min.bs_user_all_v08, N = 43,443
************************************************************************************/
proc print data=min.bs_user_all_v08 (obs=30);
title "min.bs_user_all_v08";
run;

* delete datasets;
proc delete data =min.bs_user_rygb; run;
proc delete data =min.bs_user_rygb_v01; run;
proc delete data =min.bs_user_sg; run;
proc delete data =min.bs_user_sg_v01; run;
proc delete data =min.bs_user_all_v00; run;
proc delete data =min.bs_user_all_v01; run;
proc delete data =min.bs_user_all_v02; run;
proc delete data =min.bs_user_all_v03; run;
proc delete data =min.bs_user_all_v04; run;
proc delete data =min.bs_user_all_v05; run;
proc delete data =min.bs_user_all_v06; run;
proc delete data =min.bs_user_all_v07; run;



