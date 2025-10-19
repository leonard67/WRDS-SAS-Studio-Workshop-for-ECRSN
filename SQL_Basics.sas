/**************************************************************************/
/************** WRDS SAS Studio Workshop for ECRSN.com ********************/
/*************** by Leonard Li (UNSW Sydney) ******************************/
/**************************************************************************/

/*
SELECT var1, var2, ...
FROM database_name.table_name
WHERE condition
	AND/OR condition
	LIKE/IN/BETWEEN
	<aggregate functions>
GROUP BY var1, var2, ...
HAVING condition
ORDER BY var1, var2 ... ASC/DESC;
*/

/*# 1. SELECT Statement*/

proc sql;
	CREATE TABLE Comp1 AS 
		SELECT gvkey, conm, fyear, datadate, at, prcc_f, csho 
		FROM comp.funda
		WHERE fyear = 2024;
quit;

/*## 1.1. Basic operations*/

proc sql;
	CREATE TABLE Comp2 AS 
		SELECT gvkey, conm, fyear, 
			datadate format = DATE9., 			/*Date Format*/
			at, sale, xrd, 
			(prcc_f * csho) AS MV, 				/*Math Operation*/
			LOG(at) AS Size label = "Log at" 	/*Adding label*/
		FROM comp.funda 
		WHERE fyear BETWEEN 2020 AND 2024		/*Filtering*/
			AND datafmt="STD"
			AND (NOT MISSING(at)) AND (NOT MISSING(sale))
			AND (conm LIKE "TARGET%" OR conm LIKE "APPLE%") 
			AND conm NOT LIKE "%REIT%"			/*Wildcards*/
		ORDER BY gvkey, fyear, datadate DESC; 	/*Sort data*/
quit;

/*## 1.2. CASE Statements*/
proc sql;
	CREATE TABLE Comp3 (drop = xrd) AS 
		SELECT *,
			CASE
				WHEN NOT MISSING(xrd) THEN xrd / at
				ELSE 0
			END AS RnD label = "R&D expense scaled by Total Asset, zero otherwise"
		FROM Comp2;
quit;

/*# 2. Group By*/

/*## 2.1. HAVING Clause*/
proc sql;
	CREATE TABLE Comp4 AS 
		SELECT DISTINCT *
		FROM Comp3
		GROUP BY gvkey 
		HAVING fyear = max(fyear)	/*keep one observation for each group*/
		ORDER BY gvkey;
quit;

/*## 2.2. Aggregate Functions */
proc sql;
	CREATE TABLE Comp5 AS 
		SELECT DISTINCT gvkey,
			COUNT(fyear) AS NumObs,
			COUNT(DISTINCT conm) AS NumNames, 
			AVG(at) AS AvgAT,
			MIN(at) AS MinAT,
			MAX(at) AS MaxAT,
			SUM(sale) AS TotalSales 
		FROM Comp3 
		GROUP BY gvkey 
		ORDER BY gvkey;
quit;

/*# 3. Merge and Append*/

/*## 3.1 Left Join*/
proc sql;
	CREATE TABLE Comp6 AS 
		SELECT gvkey, fyear, at 
		FROM Comp3
		WHERE fyear <= 2022
		ORDER BY gvkey, fyear;
	
	CREATE TABLE Comp7 AS 
		SELECT gvkey, fyear, sale 
		FROM Comp3
		WHERE fyear >= 2021
		ORDER BY gvkey, fyear;
	
	CREATE TABLE Left_Joined AS
		SELECT *
		FROM Comp6 LEFT JOIN Comp7 
		ON Comp6.gvkey = Comp7.gvkey
			AND Comp6.fyear = Comp7.fyear;
	
	CREATE TABLE Right_Joined AS
		SELECT b.*, a.at
		FROM Comp6 AS a RIGHT JOIN Comp7 AS b
		ON Comp6.gvkey = Comp7.gvkey
			AND Comp6.fyear = Comp7.fyear;
quit;

proc sql;
	CREATE TABLE Lag_Join AS 
		SELECT a.*, 
			b.at AS Lag_Asset,
			(a.at + b.at) / 2 AS Avg_Asset
		FROM Comp3 AS a LEFT JOIN Comp3 AS b 
			ON a.gvkey = b.gvkey
			AND a.fyear = b.fyear + 1
		ORDER BY gvkey, fyear;
quit;

/*## 3.2. Inner Join*/
proc sql;
	CREATE TABLE Inner_Joined AS
		SELECT b.*, a.at
		FROM Comp6 AS a INNER JOIN Comp7 AS b
		ON a.gvkey = b.gvkey
			AND a.fyear = b.fyear;
quit;

proc sql;
	CREATE TABLE lnk AS	
		SELECT gvkey, lpermno AS permno, linkdt, linkenddt 
		FROM crsp.ccmxpf_lnkhist
        WHERE linktype IN ("LU", "LC" , "LS")
        ORDER BY gvkey, linkdt;

    CREATE TABLE ccm AS
		SELECT a.gvkey, b.permno, a.* 
		FROM Comp3 AS a INNER JOIN lnk AS b
		ON a.gvkey = b.gvkey
			AND (b.linkdt <= a.datadate OR b.linkdt = .B) 
			AND (a.datadate <= b.linkenddt OR b.linkenddt= .E);

    CREATE TABLE ccm AS 
		SELECT a.gvkey, b.permno, a.* 
		FROM Comp3 a, lnk b
		WHERE a.gvkey = b.gvkey
			AND (b.linkdt <= a.datadate OR b.linkdt = .B) 
			AND (a.datadate <= b.linkenddt OR b.linkenddt= .E);	
quit;

/*## 3.3. Append using UNION*/
proc sql;
	CREATE TABLE af1 as
		SELECT ticker, anndats, fpedats, value, measure
		from IBES.DET_XEPSUS 
		where year(anndats) = 2024 
			and usfirm=1 
			and measure in ("GPS", "SAL")

		UNION

		SELECT ticker, anndats, fpedats, value, measure
		FROM IBES.DET_EPSUS
		WHERE year(anndats) = 2024
			AND usfirm=1
			AND measure = "EPS"

		ORDER BY ticker, anndats, measure, fpedats;
quit;

/*# 4. Subquery*/

proc sql;
	CREATE TABLE Comp8 AS
		SELECT DISTINCT *
		FROM comp.company
		WHERE gvkey IN (
			SELECT gvkey
			FROM comp.funda
			WHERE fyear = 2024
			AND at > 1000000)
		ORDER BY gvkey;
quit;

proc sql;
    CREATE TABLE ccm1 AS
		SELECT a.gvkey, b.permno, a.* 
		FROM Comp3 AS a 
			INNER JOIN 
			(SELECT gvkey, lpermno AS permno, linkdt, linkenddt 
				FROM crsp.ccmxpf_lnkhist
		        WHERE linktype IN ("LU", "LC" , "LS")) AS b
		ON a.gvkey = b.gvkey
			AND (b.linkdt <= a.datadate OR b.linkdt = .B) 
			AND (a.datadate <= b.linkenddt OR b.linkenddt= .E);
quit;