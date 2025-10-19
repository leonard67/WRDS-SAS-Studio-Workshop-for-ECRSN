/********************************************************************************/
/**************Example Code for ECRSN.com Workshop*******************************/
/****************by Leonard Li (UNSW Sydney)*************************************/

/********************************************************************************/
proc sql;

	CREATE TABLE mf1 
	AS SELECT ticker, anndats format=DATE9., 
		INTNX('month', MDY(prd_mon, 1, prd_yr),0,'e') AS MF_datadate format=DATE9., 
		pdicity,
		CASE 
			WHEN (not missing(val_2)) THEN (val_1 + val_2) / 2 
			WHEN missing(val_2) THEN val_1 
		END AS MF, mean_at_date AS Consensus 
		FROM IBES.DET_GUIDANCE WHERE year(anndats) BETWEEN 2001 AND 2019 AND usfirm=1
		AND pdicity IN ('ANN', 'QTR') AND anndats <= CALCULATED MF_datadate AND
		NOT missing(val_1) AND measure="EPS" 
		ORDER BY ticker, anndats, measure, MF_datadate, pdicity;

	CREATE TABLE Act1 AS SELECT DISTINCT ticker, INTNX('month', pends, 0,'e') AS
		datadate format=DATE9., pdicity, value AS Actual label="Actual value from IBES" 
		FROM IBES.ACT_EPSUS WHERE year(pends) >= 2001 AND usfirm=1 AND NOT missing (value) 
		AND pdicity IN ('ANN', 'QTR') AND measure="EPS" 
		ORDER BY ticker, datadate, measure, pdicity;

	/* Merge Actual Values */
	CREATE TABLE mf2 AS SELECT a.*, b.Actual FROM mf1 a LEFT JOIN Act1 b ON
		a.ticker=b.ticker AND a.pdicity=b.pdicity AND a.MF_datadate=b.datadate;

	/* Drop dulicate MFs */
	CREATE TABLE mf3 AS SELECT *, missing(Consensus) AS mark, ABS(MF - Actual)
		AS Error FROM mf2 ORDER BY ticker, anndats, MF_datadate, pdicity, mark,
		Error;

	CREATE TABLE MF_Raw (drop=mark Error) AS SELECT DISTINCT monotonic() AS N, *
		FROM mf3 GROUP BY ticker, anndats, MF_datadate, pdicity HAVING N=min(N)
		ORDER BY N;

	DROP TABLE mf1, mf2, mf3, Act, Act1;

quit;
