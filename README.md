**Welcome to WRDS SAS Studio Workshop for [ECRSN](https://www.ecrsn.com/)**

Creator: [Leonard Leye Li](https://www.unsw.edu.au/staff/leonard-leye-li)

Edition: 2025 Oct

---

### **Course Overview**

This hands-on workshop is designed to introduce PhD students and young researchers the fundamentals of using SQL within the [SAS Studio](https://wrds-cloud.wharton.upenn.edu/SASStudio/) environment on Wharton Research Data Services (WRDS). Participants will learn how to write and execute basic SQL queries, navigate the WRDS database structure, and extract and manipulate data relevant to empirical research in accounting and finance.

The session will bridge the gap between data access and empirical implementation by demonstrating how to use SQL to partially replicate main results from [one of my papers](https://doi.org/10.1111/1475-679X.12486). The goal is to equip participants with the tools and confidence to independently query large datasets, automate data extraction and cleaning, and accelerate their research workflow.

I will first go through the basic syntax of SQL using the [SQL_Basics](./SQL_Basics.sas) file. Then I will show the codes of partially replicating my paper using the [Example_Codes](Example_Codes.sas) file.


---

### **Learning Outcomes**

By the end of this workshop, participants will be able to:

1. **Understand SQL Basics in SAS Studio:**

   * Learn the structure and syntax of SQL commands such as `SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`, and `ORDER BY`.
   * Understand how SQL integrates into SAS Studio on WRDS.

2. **Navigate the WRDS Environment:**

   * Access and explore key WRDS datasets (e.g., CRSP, Compustat, IBES).
   * Use the WRDS data dictionary and metadata tools to understand variable definitions and dataset structure.

3. **Write and Execute SQL Queries:**

   * Extract variables of interest using efficient SQL queries.
   * Merge datasets using `JOIN` operations across common identifiers.

4. **Implement Research-Oriented Data Extraction:**

   * Use SQL to reproduce key variable constructions from a published paper.
   * Understand how to clean and filter data directly in SQL to support empirical tests.

5. **Apply Best Practices in Reproducible Research:**

   * Organize code and queries for clarity and reproducibility.
   * Learn strategies to troubleshoot errors and optimize query performance.

---

### Rrerequisite reading:

Chen, C., Li, L. L., Lu, L. Y., & Wang, R. (2023). Flu fallout: Information production constraints and corporate disclosure. *Journal of Accounting Research*, 61(4), 1063-1108. ([link](https://doi.org/10.1111/1475-679X.12486))

### Note:

In the workshop I will show the example codes to partly replicate the simplified results of Chen et al. (2023). The actual process of producing the main results of the paper is much more complicated. For full replication, please see: https://www.chicagobooth.edu/research/chookaszian/journal-of-accounting-research/online-supplements-and-datasheets/volume-61.
