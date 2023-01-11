USE BANK_PROJECT

------------------------------Designing data model by merging tables-------------------------------

SELECT * FROM Account_Perfrmance_Data;
SELECT * FROM Employer_details;


SELECT 
A.Account_number,
A.PORTFOLIO,
A.SSN,
A.Phone_No ,
A.Place_Name,
A.County,
A.City,
A.State,
A.Zip,
A.Region,
A.Account_Open_Date,
A.Last_payment_date,
A.Loan_amount,
A.loan_status,
A.Origination_fico_score,
A.Current_fico_score,
A.Current_outstanding,
B.CUSTOMER_NUMBER,
B.COMPANY_NAME,
B.PRIMARY_INDUSTRY,
B.REVENUES_IN_MILLIONS_DOLLAR,
B.CATEGORY
INTO NEW_CUSTOMER_TABLE
FROM Account_Perfrmance_Data AS A
LEFT JOIN
Employer_details AS B
ON
A.ACCOUNT_NUMBER=B.ACCOUNT_NUMBER;


SELECT * FROM NEW_CUSTOMER_TABLE;

----------------Get Month on Booking (MOB) from Account Open Date to Current Date----------------------------------------


SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
DATEDIFF(MONTH,ACCOUNT_OPEN_DATE,GETDATE())AS MONTH_ON_BOOKING,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
Current_outstanding,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
INTO NEW_CUSTOMER_TABLE1
FROM NEW_CUSTOMER_TABLE;


--===========================================================================================================
--------------Get Delinquency days (Loan Defaulted by number of days)

SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
CASE WHEN loan_status='Non-Default' then 0
Else datediff(day,last_payment_date,getdate())
end as Delinquency_days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
Current_outstanding,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
into NEW_CUSTOMER_TABLE2
FROM NEW_CUSTOMER_TABLE1;

--===================================================================================================
--Create Delinquency Bucket Days	Delinqency Days=0	Current
--	>0 and <=30	X Days
--	>30 and <=60	X+1 Days
--	>60 and <=90	X+2 Days
--	>90 and <=120	X+3 Days
--	>120 and <=150	X+4 Days
--	>150 and <=180	X+5 Days
--	>180	Charge Off

SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
Delinquency_days,
case when Delinquency_days>180 then 'Charge off'
when Delinquency_days >150 and Delinquency_days<=180 then 'X+5 Days'
when Delinquency_days >120 and Delinquency_days<=150 then 'X+4 Days'
when Delinquency_days >90 and Delinquency_days<=120 then 'X+3 Days'
when Delinquency_days >60 and Delinquency_days<=90 then 'X+2 Days'
when Delinquency_days >30 and Delinquency_days<=60 then 'X+1 Days'
when Delinquency_days >0 and Delinquency_days<=30 then 'X Days'
else 'Current'
end as Delinquency_Bucket_Days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
Current_outstanding,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
FROM NEW_CUSTOMER_TABLE2;


--=================================================================================================================
--Create Origination vs Currect Fico score variance in %
SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
Delinquency_days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
Format((Current_fico_score-Origination_fico_score)/(Origination_fico_score),'P0') as Variance ,
Current_outstanding,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
into NEW_CUSTOMER_TABLE3
FROM NEW_CUSTOMER_TABLE2;


--====================================================================================================
--Current Outstanding Balance in %
SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
Delinquency_days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
Current_outstanding,
variance,
Format((Current_outstanding)/Loan_amount ,'P0') as oustanding_balance,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
into NEW_CUSTOMER_TABLE4
FROM NEW_CUSTOMER_TABLE3;

--=====================================================================================================
----------Develop Risk Segment	Delinquency Days <=60	High-Risk-1
----------	Score Variance in Negative %	
----------	Outstanding Balance % >= 50%	
----------	Delinquency Days > 60	High-Risk-2
----------	Score Variance in Negative %	
----------	Outstanding Balance % >= 50%	
----------	Delinquency Days <= 60	High-Risk-3
----------	Score Variance in Negative %	
----------	Outstanding Balance % >30% and < 50%	
----------	Delinquency Days> 60	High-Risk-4
----------	Score Variance in Negative %	
----------	Outstanding Balance % >30% and < 50%	
----------	Delinquency Days <= 60	Mid_Risk-1
----------	Score Variance in Negative %	
----------	Outstanding Balance % >10% and < =30%	
----------	Delinquency Days > 60	Mid_Risk-2
----------	Score Variance in Negative %	
----------	Outstanding Balance % >10% and < =30%	
----------	Else 	Low_risk

--STEP-1
SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
Delinquency_days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
CAST(CONVERT(int, replace(variance,'%','')) as INT) as variance,
Current_outstanding,
CAST(CONVERT(int, replace(oustanding_balance,'%','')) as INT) as oustanding_balance,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY
INTO NEW_CUSTOMER_TABLE5
FROM NEW_CUSTOMER_TABLE4;

--STEP-2
SELECT
Account_number,
PORTFOLIO,
SSN,
Phone_No ,
Place_Name,
County,
City,
State,
Zip,
Region,
Account_Open_Date,
MONTH_ON_BOOKING,
Delinquency_days,
Last_payment_date,
Loan_amount,
loan_status,
Origination_fico_score,
Current_fico_score,
variance,
Current_outstanding,
oustanding_balance,
CUSTOMER_NUMBER,
COMPANY_NAME,
PRIMARY_INDUSTRY,
REVENUES_IN_MILLIONS_DOLLAR,
CATEGORY,
CASE WHEN Delinquency_Days <=60 AND 
Variance>0 And 
oustanding_balance>=50 then 'High_Risk_1'
WHEN Delinquency_Days >60 AND 
Variance>0 And 
oustanding_balance>=50 then 'High_Risk_2'
WHEN Delinquency_Days <=60 AND 
Variance>0 And 
oustanding_balance>30 and oustanding_balance<50 then 'High_Risk_3'
WHEN Delinquency_Days >60 AND 
Variance>0 And 
oustanding_balance>30 and oustanding_balance<50 then 'High_Risk_4'
WHEN Delinquency_Days <=60 AND 
Variance>0 And 
oustanding_balance>10 and oustanding_balance<=30 then 'Mid_Risk_1'
WHEN Delinquency_Days >60 AND 
Variance>0 And 
oustanding_balance>10 and oustanding_balance<=30 then 'Mid_Risk_2'
else 'low_risk'
end as Risk_segment
FROM NEW_CUSTOMER_TABLE5;