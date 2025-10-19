/***********************************************************************************************/
/*************************************Example Codes ********************************************/
/*Here I show an example of partly replicate the simplified results of Chen et al. (2023)*******/
/*Note that the actual process of producing the main results of the paper is much more *********/
/*complicated. For full code, see:**************************************************************/
/*https://www.chicagobooth.edu/research/chookaszian/journal-of-accounting-research/online-supplements-and-datasheets/volume-61*/
/***********************************************************************************************/
%include '/home/agsm/leonardl/ECRSN Workshop/Gvkey-IBES.sas';
%include '/home/agsm/leonardl/ECRSN Workshop/fundq_example.sas';
%include '/home/agsm/leonardl/ECRSN Workshop/MF_Example.sas';

PROC IMPORT DATAFILE= '/home/agsm/leonardl/ECRSN Workshop/Flu.csv'
	DBMS=CSV
	OUT=WORK.Flu;
	GETNAMES=YES;
run;

proc sql;
    CREATE TABLE Step1 AS
    	SELECT DISTINCT a.*, avg(Flu) as Flu 
    	FROM Comp_Quarter a INNER JOIN Flu b 
    		ON a.State_Comp = b.State
    		AND b.Weekend BETWEEN a.datadate AND a.F_EA_date
    	GROUP BY gvkey, datadate; 		/*We define this window as the period between the end of the fiscal period and the EA date.*/

   CREATE TABLE Step2 AS
    	SELECT a.*, 
    		CASE
    			WHEN SUM(anndats) > 0 THEN 1
    			ELSE 0
    		END AS Issue_Short
    	FROM Step1 AS a LEFT JOIN (
    			SELECT ticker, anndats FROM MF_Raw WHERE (MF_datadate - anndats) < 91 ) AS b 
    	ON a.ticker = b.ticker
    		AND b.anndats BETWEEN (a.F_EA_date - 1) AND (a.F_EA_date + 1)
    	GROUP BY a.gvkey, a.datadate;

   CREATE TABLE Step3 AS
    	SELECT a.*, 
    		CASE
    			WHEN SUM(anndats) > 0 THEN 1
    			ELSE 0
    		END AS Issue_Long
    	FROM Step2 AS a LEFT JOIN (
    			SELECT ticker, anndats FROM MF_Raw WHERE (MF_datadate - anndats) >= 91 ) AS b 
    	ON a.ticker = b.ticker
    		AND b.anndats BETWEEN (a.F_EA_date - 1) AND (a.F_EA_date + 1)
    	GROUP BY a.gvkey, a.datadate;

   CREATE TABLE Step4 (drop = Ever_Short Ever_Long) AS
   		SELECT *
   		FROM (
   			SELECT *, MAX(Issue_Short) AS Ever_Short, MAX(Issue_Long) AS Ever_Long 
			FROM Step3 
			GROUP BY gvkey
   			)
   		WHERE Ever_Short = 1 OR Ever_Long = 1;
quit;

proc reg data = Step4;
	model Issue_Short = Flu Size;
	model Issue_Long = Flu Size;
run;