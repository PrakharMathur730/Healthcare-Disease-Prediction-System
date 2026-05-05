# Healthcare Analytics SQL Project
 
# USE DATABASE

USE Healthcare;

-- ==========================================
-- SECTION 1: TABLE STRUCTURE OVERVIEW
-- ==========================================

Show columns From dataset;

Show columns from symptom_precaution;

Show columns from symptom_severity;

Show columns from patient_records;

-- ==========================================
-- SECTION 2: BASIC Overview
-- ==========================================

-- Total number of records in dataset
SELECT COUNT(*) AS Total_Records FROM dataset;


-- Total number of unique diseases
SELECT COUNT(DISTINCT Disease) AS Unique_Diseases FROM dataset;

-- =========================================
-- SECTION 3: DISEASE ANALYSIS
-- =========================================

-- Top 10 most frequent diseases
SELECT Disease, COUNT(*) AS Occurrences
FROM dataset
GROUP BY Disease
ORDER BY Occurrences DESC
LIMIT 10;

-- ==========================================
-- SECTION 4: SYMPTOM ANALYSIS
-- ==========================================

-- Disease with Highest Cases
SELECT Disease, COUNT(*) AS cases
FROM patient_records
GROUP BY Disease
ORDER BY cases DESC
LIMIT 1;

-- Disease with Highest Recovery Time
SELECT Disease, AVG(Recovery_Days) AS avg_recovery
FROM patient_records
GROUP BY Disease
ORDER BY avg_recovery DESC
LIMIT 1;

-- =========================================
-- SECTION 5: SYMPTOM ANALYSIS
-- =========================================

--  Most Common Symptoms (Top 20)
SELECT symptom, COUNT(*) AS frequency
FROM (
    SELECT Symptom_1 AS symptom FROM dataset
    UNION ALL SELECT Symptom_2 FROM dataset
    UNION ALL SELECT Symptom_3 FROM dataset
    UNION ALL SELECT Symptom_4 FROM dataset
    UNION ALL SELECT Symptom_5 FROM dataset
    UNION ALL SELECT Symptom_6 FROM dataset
) AS All_Symptoms
WHERE symptom IS NOT NULL AND symptom != 'None' AND TRIM(symptom) != ''
GROUP BY symptom
ORDER BY frequency DESC
LIMIT 20;

-- Symptom Frequency
SELECT Symptom, COUNT(*) AS frequency
FROM symptom_severity
GROUP BY Symptom
ORDER BY frequency DESC;

-- =========================================
-- SECTION 6: RELATIONSHIP ANALYSIS
-- =========================================

-- Diseases associated with a specific symptom
SELECT DISTINCT Disease
FROM dataset
WHERE Symptom_1 = 'itching'
   OR Symptom_2 = 'itching'
   OR Symptom_3 = 'itching'
   OR Symptom_4 = 'itching'
   OR Symptom_5 = 'itching'
   OR Symptom_6 = 'itching'
ORDER BY Disease;


-- Average number of symptoms per disease
SELECT Disease,
    ROUND(AVG(
        (CASE WHEN Symptom_1 IS NOT NULL AND Symptom_1 != 'None' THEN 1 ELSE 0 END) +
        (CASE WHEN Symptom_2 IS NOT NULL AND Symptom_2 != 'None' THEN 1 ELSE 0 END) +
        (CASE WHEN Symptom_3 IS NOT NULL AND Symptom_3 != 'None' THEN 1 ELSE 0 END) +
        (CASE WHEN Symptom_4 IS NOT NULL AND Symptom_4 != 'None' THEN 1 ELSE 0 END) +
        (CASE WHEN Symptom_5 IS NOT NULL AND Symptom_5 != 'None' THEN 1 ELSE 0 END) 
    ), 2) AS Avg_Symptoms
FROM dataset
GROUP BY Disease
ORDER BY Avg_Symptoms DESC;


-- ==========================================
-- SECTION 7: PRECAUTION ANALYSIS
-- ==========================================

-- Precautions for a specific disease
SELECT * FROM symptom_precaution WHERE Disease = 'Jaundice';


-- Most Common Precautions
SELECT precaution, COUNT(*) AS frequency
FROM (
    SELECT Precaution_1 AS precaution FROM symptom_precaution
    UNION ALL SELECT Precaution_2 FROM symptom_precaution
    UNION ALL SELECT Precaution_3 FROM symptom_precaution
    UNION ALL SELECT Precaution_4 FROM symptom_precaution
) AS all_precautions
WHERE precaution IS NOT NULL AND TRIM(precaution) != ''
GROUP BY precaution
ORDER BY frequency DESC
LIMIT 15;

-- =========================================
-- SECTION 8: DEMOGRAPHICS ANALYSIS
-- =========================================

-- Gender Distribution
SELECT Gender, COUNT(*) AS total
FROM patient_records
GROUP BY Gender;

-- Region-wise Patient Count
SELECT Region, COUNT(*) AS total
FROM patient_records
GROUP BY Region;

-- =========================================
-- SECTION 9: ADVANCED ANALYSIS
-- =========================================

-- Running Total of Disease Cases 
SELECT Disease, Occurrences,
    SUM(Occurrences) OVER (ORDER BY Occurrences DESC) AS Running_Total,
    ROUND(SUM(Occurrences) OVER (ORDER BY Occurrences DESC) * 100.0 / SUM(Occurrences) OVER (), 2) AS Cumulative_Pct
FROM (
    SELECT Disease, COUNT(*) AS Occurrences
    FROM dataset
    GROUP BY Disease
) AS disease_freq
ORDER BY Occurrences DESC;

-- Join Disease with Precautions
SELECT 
    d.Disease,
    COUNT(*) AS Record_Count,
    sp.Precaution_1,
    sp.Precaution_2,
    sp.Precaution_3,
    sp.Precaution_4
FROM dataset d
LEFT JOIN symptom_precaution sp ON d.Disease = sp.Disease
GROUP BY d.Disease, sp.Precaution_1, sp.Precaution_2, sp.Precaution_3, sp.Precaution_4
ORDER BY Record_Count DESC;

-- =========================================
-- SECTION 10: STORED PROCEDURE
-- =========================================

-- Drop if already exists (for re-run safety)
DROP PROCEDURE IF EXISTS GetDiseasesBySymptom;

-- Stored procedure to predict diseases by symptoms
DELIMITER //

CREATE PROCEDURE GetDiseasesBySymptom(IN input_symptom VARCHAR(100))
BEGIN
    SELECT DISTINCT Disease, COUNT(*) AS Match_Score
    FROM dataset
    WHERE Symptom_1 = input_symptom
       OR Symptom_2 = input_symptom
       OR Symptom_3 = input_symptom
       OR Symptom_4 = input_symptom
       OR Symptom_5 = input_symptom
       OR Symptom_6 = input_symptom
    GROUP BY Disease
    ORDER BY Match_Score DESC;
END //

DELIMITER ;


-- ==========================================
-- SECTION 11: ADVANCED ANALYTICS (Window Functions)
-- ==========================================

-- Disease-wise Patient Count
SELECT Disease, COUNT(*) AS patient_count
FROM patient_records
GROUP BY Disease
ORDER BY patient_count DESC;

-- Average Recovery Time per Disease
SELECT Disease, AVG(Recovery_Days) AS avg_recovery
FROM patient_records
GROUP BY Disease;


-- ==========================================
-- SECTION 12: VIEWS FOR DASHBOARD INTEGRATION
-- ==========================================

-- Create View: Disease Summary (for dashboard KPIs & ranking)
CREATE OR REPLACE VIEW disease_summary AS
SELECT 
    Disease,
    COUNT(*) AS Total_Records,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS Popularity_Rank
FROM dataset
GROUP BY Disease;

-- Create View: Symptom Frequency (for charts & analysis)
CREATE OR REPLACE VIEW symptom_dashboard AS
SELECT symptom, COUNT(*) AS frequency
FROM (
    SELECT Symptom_1 AS symptom FROM dataset
    UNION ALL SELECT Symptom_2 FROM dataset
    UNION ALL SELECT Symptom_3 FROM dataset
    UNION ALL SELECT Symptom_4 FROM dataset
    UNION ALL SELECT Symptom_5 FROM dataset
    UNION ALL SELECT Symptom_6 FROM dataset
) AS all_symptoms
WHERE symptom IS NOT NULL AND symptom != 'None'
GROUP BY symptom;

-- Query Views (used in Power BI / reporting)
SELECT * FROM disease_summary ORDER BY Popularity_Rank LIMIT 15;
SELECT * FROM symptom_dashboard ORDER BY frequency DESC LIMIT 15;






