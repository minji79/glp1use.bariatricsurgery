
/************************************************************************************
	STEP 1. Make total studypopulation dataset incl. comorbidity & co-medication & bmi_at_baseline
************************************************************************************/

/**************************************************
* new dataset: min.studypopulation_v01
* original dataset: min.bs_glp1_user_v03
* description: 
**************************************************/

* dataset for comorbidity at baseline;
proc sql;
    create table min.comorbidity as
    select distinct a.patient_id, 
           b0.cc_t2db,
           b1.cc_obs,
           b2.cc_htn,
           b3.cc_dyslip,
           b4.cc_osa,
           b5.cc_cad,
           b6.cc_hf,
           b7.cc_af,
           b8.cc_asthma,
           b9.cc_liver,
           b10.cc_ckd,
           b11.cc_pos,
           b12.cc_infertility,
           b13.cc_gerd
    from min.bs_glp1_user_v03 a 
    left join min.bs_user_comorbidity_t2db b0 on a.patient_id = b0.patient_id
    left join min.bs_user_comorbidity_obs b1 on a.patient_id = b1.patient_id
    left join min.bs_user_comorbidity_htn b2 on a.patient_id = b2.patient_id
    left join min.bs_user_comorbidity_dyslip b3 on a.patient_id = b3.patient_id
    left join min.bs_user_comorbidity_osa b4 on a.patient_id = b4.patient_id
    left join min.bs_user_comorbidity_cad b5 on a.patient_id = b5.patient_id
    left join min.bs_user_comorbidity_hf b6 on a.patient_id = b6.patient_id
    left join min.bs_user_comorbidity_af b7 on a.patient_id = b7.patient_id
    left join min.bs_user_comorbidity_asthma b8 on a.patient_id = b8.patient_id
    left join min.bs_user_comorbidity_liver b9 on a.patient_id = b9.patient_id
    left join min.bs_user_comorbidity_ckd b10 on a.patient_id = b10.patient_id
    left join min.bs_user_comorbidity_pos b11 on a.patient_id = b11.patient_id
    left join min.bs_user_comorbidity_infertility b12 on a.patient_id = b12.patient_id
    left join min.bs_user_comorbidity_gerd b13 on a.patient_id = b13.patient_id;
    
quit;

* dataset for co-medication at baseline;
proc sql;
    create table min.comedication as
    select distinct a.patient_id, 
           b.cm_metformin,
           b.cm_dpp4,
           b.cm_sglt2,
           b.cm_su,
           b.cm_thiaz,
           b.cm_insul,
           b.cm_depres, 
           b.cm_psycho,
           b.cm_convul,
           b.cm_ob
    from min.bs_glp1_user_v03 a 
    left join min.bs_user_comedication_v09 b on a.patient_id = b.patient_id;
quit;

* dataset for bmi_index measured at baseline;
proc sql;
    create table min.studypopulation_v00 as
    select distinct a.*,
            b.bmi as bmi_index
    from min.bs_glp1_user_v03 a 
    left join min.bs_glp1_bmi_baseline b on a.patient_id = b.patient_id;
quit;

proc contents data=min.studypopulation_v00; run;

* add comorbidity and co-medication to the studypopulation;
proc sql;
    create table min.studypopulation_v01 as
    select distinct a.*, 
           b1.cc_t2db,
           b1.cc_obs,
           b1.cc_htn,
           b1.cc_dyslip,
           b1.cc_osa,
           b1.cc_cad,
           b1.cc_hf,
           b1.cc_af,
           b1.cc_asthma,
           b1.cc_liver,
           b1.cc_ckd,
           b1.cc_pos,
           b1.cc_infertility,
           b1.cc_gerd,

           b2.cm_metformin,
           b2.cm_dpp4,
           b2.cm_sglt2,
           b2.cm_su,
           b2.cm_thiaz,
           b2.cm_insul,
           b2.cm_depres, 
           b2.cm_psycho,
           b2.cm_convul,
           b2.cm_ob
           
    from min.studypopulation_v00 a 
    left join min.comorbidity b1 on a.patient_id = b1.patient_id
    left join min.comedication b2 on a.patient_id = b2.patient_id;
   
quit;

* fill null -> 0;
data min.studypopulation_v01;
  set min.studypopulation_v01;
  if missing(cc_t2db) then cc_t2db = 0;
  if missing(cc_obs) then cc_obs = 0;
  if missing(cc_htn) then cc_htn = 0;
  if missing(cc_dyslip) then cc_dyslip = 0;
  if missing(cc_osa) then cc_osa = 0;
  if missing(cc_cad) then cc_cad = 0;
  if missing(cc_hf) then cc_hf = 0;
  if missing(cc_af) then cc_af = 0;
  if missing(cc_asthma) then cc_asthma = 0;
  if missing(cc_liver) then cc_liver = 0;
  if missing(cc_ckd) then cc_ckd = 0;
  if missing(cc_pos) then cc_pos = 0;
  if missing(cc_infertility) then cc_infertility = 0;
  if missing(cc_gerd) then cc_gerd = 0;
  
run;

/************************************************************************************
	STEP 2. Table 1 covariate with p value
************************************************************************************/

/**************************************************
* new dataset: min.studypopulation_v02
* original dataset: min.studypopulation_v01
**************************************************/

/***********************************************************
How to calculate p-value?

1. continuous variables

/* Perform a t-test for continuous variables */
proc ttest data=mydata;
   class group;
   var bmi;
run;

/* Extract the p-value from the t-test result */
data ttest_pvalue;
    set ttest_results;
    where Method = "Pooled";
    pvalue_bmi = ProbT;
    keep pvalue_bmi;
run;

2. categorical variables

/* Perform a Chi-Square Test for categorical variables */
proc freq data=mydata;
   tables group*gender / chisq;
   ods output ChiSq=chisq_results;
run;

/* Extract the p-value from the chi-square result */
data chisq_pvalue;
    set chisq_results;
    where Statistic = "Chi-Square";
    pvalue_gender = Prob;
    keep pvalue_gender;
run;
************************************************************/

* 1.1. Age;
proc sort data=min.studypopulation_v01 out = min.studypopulation_v01;
  by temporality;
run;

proc means data=min.studypopulation_v01
  n nmiss median mean min max std maxdec=1;
  var age_at_bs;
  title "age_cont";
run;

proc means data=min.studypopulation_v01
  n nmiss median mean min max std maxdec=1;
  var age_at_bs;
  by temporality;
  title "age_cont";
run;

/* p-value */
proc ttest data=min.studypopulation_v01;
   class temporality;
   var age_at_bs;
run;


* 1.2. Age - categorized;
/**************************************************
* new dataset: min.studypopulation_v02
* original dataset: min.studypopulation_v01
* description: Age - categorized, bmi_at_baseline - categorized
**************************************************/

data min.studypopulation_v02;
  set min.studypopulation_v01;
  format age_cat 8.;
  if 18 <= age_at_bs and age_at_bs < 30 then age_cat=2;
  else if 30 <= age_at_bs and age_at_bs < 40 then age_cat=3;
  else if 40 <= age_at_bs and age_at_bs < 50 then age_cat=4;
  else if 50 <= age_at_bs and age_at_bs < 60 then age_cat=5;
  else if 60 <= age_at_bs and age_at_bs < 70 then age_cat=6;
  else if 70 <= age_at_bs and age_at_bs < 80 then age_cat=7;
  else if 80 <= age_at_bs and age_at_bs      then age_cat=8;  
run;

/* analysis for total cohort */
proc sort data=min.studypopulation_v02;
  by age_cat;
run;
proc means data=min.studypopulation_v02
n nmiss median mean min max std;
  var age_at_bs;
  by age_cat;
  title "age_cat";
run;
proc freq data=min.studypopulation_v02;
  tables age_cat*temporality / chisq;
run;

* 1.3. bmi_at_baseline - categorized;

data min.studypopulation_v02;
  set min.studypopulation_v02;
  format bmi_index_cat 8.;
  if missing(bmi_index) then bmi_index_cat=0;                              /* missing */
  else if bmi_index < 18.5 then bmi_index_cat=1;                           /* underweight */
  else if 18.5 <= bmi_index and bmi_index < 25.0 then bmi_index_cat=2;     /* healthy weight */
  else if 25.0 <= bmi_index and bmi_index < 30.0 then bmi_index_cat=3;     /* over weight */
  else if 30.0 <= bmi_index and bmi_index < 35.0 then bmi_index_cat=4;     /* obesity - class 1 */
  else if 35.0 <= bmi_index and bmi_index < 40.0 then bmi_index_cat=5;     /* obesity - class 2 */
  else if 40.0 <= bmi_index then bmi_index_cat=6;                          /* obesity - class 3 */
  
run;

/* see distribution */
proc sgplot data=min.studypopulation_v02;
    histogram bmi_index;
    title "BMI at Baseline";
run;

proc freq data=min.studypopulation_v02;
  tables bmi_index_cat*temporality / chisq;
  title "bmi_index_cat distribution";
run;

* 1.4. Sex;
proc freq data=min.studypopulation_v02;
  tables sex*temporality / chisq;
  title "sex distribution";
run;

* 1.5. Race;
proc freq data=min.studypopulation_v02;
  tables race*temporality / chisq;
  title "race distribution";
run;

* 1.6. Ethnicity; 
proc freq data=min.studypopulation_v02;
  tables ethnicity*temporality / chisq;
  title "Ethnicity distribution";
run;

* 1.7. Marital status;
proc freq data=min.studypopulation_v02;
  tables marital_status*temporality / chisq;
  title "marital_status distribution";
run;

* 1.8. Regional location;
proc freq data=min.studypopulation_v02;
  tables patient_regional_location*temporality / chisq;
  title "patient_regional_location distribution";
run;

* 1.9. BS_type;
proc freq data=min.studypopulation_v02;
  tables bs_type*temporality / chisq;
  title "bs_type distribution";
run;


* 1.10. glp1_type_cat;
proc freq data=min.studypopulation_v02;
  tables Molecule*temporality;
  title "Molecule distribution";
run;


* 1.11. bmi_index;
proc means data=min.studypopulation_v02
	n nmiss mean std min max median p25 p75;
 	var bmi_index;
  	title "distribution of bmi_index";
run;

/* p-value */
proc ttest data=min.studypopulation_v02;
   class temporality;
   var bmi_index;
run;

* 1.12. comorbidities;

proc freq data=min.studypopulation_v02; tables temporality * cc_t2db / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_obs / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_htn / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_dyslip / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_osa / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_cad / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_hf / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_af / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_liver / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_asthma / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_ckd / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_pos / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cc_gerd / chisq; run;

* 1.13. comedication;

proc freq data=min.studypopulation_v02; tables temporality * cm_metformin / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_dpp4 / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_sglt2 / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_su / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_thiaz / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_insul / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_ob / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_depres / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_psycho / chisq; run;
proc freq data=min.studypopulation_v02; tables temporality * cm_convul / chisq; run;


* 1.14. Make time-to-initiation variable;

data min.studypopulation_v02;
    set min.studypopulation_v02;
    format time_to_glp1_cat 8.;
    
    /* Calculate the time difference in days */
    time_diff = glp1_initiation_date - bs_date;

    /* Categorize based on time difference */
    if missing(glp1_initiation_date) then time_to_glp1_cat = 0;       /* non-users */
    else if 0    <= time_diff < 365 then time_to_glp1_cat = 1;        /* started within 1 year */
    else if 365  <= time_diff < 730 then time_to_glp1_cat = 2;        /* started between 1-2 years */
    else if 730  <= time_diff < 1095 then time_to_glp1_cat = 3;       /* started between 2-3 years */
    else if 1095 <= time_diff < 1460 then time_to_glp1_cat = 4;       /* started between 3-4 years */
    else if 1460 <= time_diff < 1825 then time_to_glp1_cat = 5;       /* started between 4-5 years */
    else if 1825 <= time_diff < 2190 then time_to_glp1_cat = 6;       /* started between 5-6 years */
    else if 2190 <= time_diff < 2555 then time_to_glp1_cat = 7;       /* started between 6-7 years */
    else if time_diff >= 2555 then time_to_glp1_cat = 8;              /* started after 7 years */

    drop time_diff;
run;

proc freq data=min.studypopulation_v02;
	tables time_to_glp1_cat;
 	title "distribution of time-to-initiation cat";
run;

* 3.11. BMI various values;
/*
variables' name
bmi_1y_bf | BMI 1 year before the BS date
bmi_6m_bf | BMI 6 months before the BS date
bmi_1y_af | BMI 1 year after the BS date
bmi_2y_af | BMI 2 years after the BS date
bmi_3y_af | BMI 3 years after the BS date
*/

/* bmi_1y_bf */
proc ttest data=min.bs_glp1_bmi_1y_bf_v02;
   class temporality;
   var bmi;
run;

/* bmi_6m_bf */
proc ttest data=min.bs_glp1_bmi_6m_bf_v02;
   class temporality;
   var bmi;
run;

/* bmi_1y_af */
proc ttest data=min.bs_glp1_bmi_1y_af_v02;
   class temporality;
   var bmi;
run;

/* bmi_2y_af */
proc ttest data=min.bs_glp1_bmi_2y_af_v02;
   class temporality;
   var bmi;
run;

/* bmi_3y_af */
proc ttest data=min.bs_glp1_bmi_3y_af_v02;
   class temporality;
   var bmi;
run;
