CREATE DATABASE HumanitarianProgramDB;
USE HumanitarianProgramDB;

   CREATE TABLE jurisdiction_hierarchy(
         ID INT PRIMARY KEY AUTO_INCREMENT,
         Name VARCHAR (30) UNIQUE NOT NULL ,
         levels VARCHAR (20) NOT NULL, CHECK (levels IN ('County','Sub-county','Village')),
         Parent VARCHAR (30) NULL , 
         FOREIGN KEY (Parent) REFERENCES jurisdiction_hierarchy(Name)
         ON DELETE CASCADE
         );

        
CREATE TABLE village_locations(
	 Village_ID INT PRIMARY KEY AUTO_INCREMENT,
     Village VARCHAR (30)  UNIQUE NOT NULL ,
     Total_population INT NOT NULL , CHECK ( Total_population >=0),
	 FOREIGN KEY (Village) REFERENCES jurisdiction_hierarchy(Name) 
     ON DELETE CASCADE
     );
     
     
     CREATE TABLE beneficiary_partner_data(
     Partner_ID INT PRIMARY KEY AUTO_INCREMENT,
     Partner VARCHAR (30) NOT NULL,
     Village VARCHAR (30) NOT NULL , 
     Beneficiaries INT NOT NULL ,CHECK (beneficiaries >= 0),
     Beneficiary_type VARCHAR (30) NOT NULL CHECK (Beneficiary_type IN ('Individuals','Households')),
     FOREIGN KEY (Village) REFERENCES village_locations(village) 
     ON DELETE CASCADE
     );
 
 
DESCRIBE beneficiary_partner_data;
SELECT * FROM beneficiary_partner_data;
     
INSERT INTO beneficiary_partner_data( Partner_ID, Partner, Village,Beneficiaries,Beneficiary_type)
     VALUES
    (1 ,'IRC', 'Parklands',1450,'Individuals'),
    (2 ,'NRC','Parklands',50,'Households'),
    (3, 'SCI' ,'Kangemi',1123,'Individuals'),
    (4 , 'IMC', 'Kangemi' ,1245, 'Individuals'),
    (5 ,'CESVI','Roysambu',5200,'Individuals'),
    (6 , 'IMC' ,'Githurai' ,70,'Households'),
    (7 ,'IRC','Githurai',2100,'Individuals'),
    (8,'SCI','Kiamwangi',1800,'Individuals'),
    (9,'IMC','Lari Town',1340,'Individuals'),
    (10,'CESVI','Kamwangi',55,'Households'),
    (11,'IRC','Kisauni Town',4500,'Individuals'),
    (12,'SCI','Kisauni Town',1670,'Individuals'),
    (13,'IMC','Mtopanga',1340,'Individuals'),
    (14,'CESVI','Likoni Town',4090,'Individuals'),
    (15,'IRC','Shika Adabu',2930,'Individuals'),
   (16,'SCI','Shika Adabu',5200,'Individuals');
       
DESCRIBE village_locations;
SELECT * FROM village_locations;
  INSERT INTO village_locations(Village_ID ,Village ,Total_population)
    VALUES  
    ( 1 , 'Parklands' ,15000),
	(2 , 'Kangemi' ,18000),
    (3 , 'Roysambu' ,13000),
    (4 , 'Githurai' ,125000),
    (5 , 'Kiamwangi' , 12800),
	(6 , 'Lari Town', 9485) ,
	(7, 'Kamwangi' ,5212),
    (8 ,'Kisauni Town',20500),
    (9 , 'Mtopanga',15500),
    (10, 'Likoni Town',12000),
    (11 ,'Shika Adabu',9000);
   
DESCRIBE jurisdiction_hierarchy;
SELECT * FROM jurisdiction_hierarchy;
   
   INSERT INTO jurisdiction_hierarchy (ID ,Name ,levels,Parent)
    VALUES 
    (1 ,'Nairobi' , 'County', NULL),
    (2 ,  'Kiambu',   'County', NULL),
    (3 ,'Mombasa',   'County',NULL),
    
    (4 , 'Westlands', 'Sub-County','Nairobi'),
    (5 ,'Kasarani', 'Sub-County','Nairobi'),
    (6 ,'Lari', 'Sub-County' , 'Kiambu'),
    (7 ,'Gatundu South', 'Sub-County' ,'Kiambu'),
	(8 ,'Kisauni'  ,'Sub-County' ,'Mombasa'),
    (9 ,'Likoni', 'Sub-County', 'Mombasa'),
    
    (10 ,'Parklands','Village','Westlands'),
	(11 ,'Kangemi',  'Village','Westlands'),
    (12 , 'Roysambu', 'Village', 'Kasarani'),
    (13 ,'Githurai', 'Village' ,'Kasarani'),
    (14 , 'Kiamwangi' , 'Village' ,'Lari'),
    (15 , 'Lari Town' , 'Village','Lari'),
    (16 , 'Kamwangi' , 'Village' ,'Gatundu South'),
    (17 , 'Kisauni Town' , 'Village' ,'Kisauni'),
    (18 , 'Mtopanga' ,'Village','Kisauni'),
    (19 , 'Likoni Town' ,'Village' ,'Likoni'),
    (20 , 'Shika Adabu' ,'Village','Likoni');
    
    
    ## 1.AGGREGATE FUNCTIONS ,GROUP BY & CASE WHEN
    #Total Beneficiaries per partner (Households must be converted to 1 household = 6 individuals
    # using CASE WHEN
    SELECT 
    partner,
    SUM(
        CASE 
            WHEN Beneficiary_type = 'Households' THEN beneficiaries * 6
            ELSE Beneficiaries
        END
    ) AS total_individual_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner;

#Count number of villages served per partner
SELECT 
    partner,
    COUNT(DISTINCT village) AS villages_served
FROM beneficiary_partner_data
GROUP BY partner;

#Average beneficiaries per village
SELECT 
    village,
    AVG(beneficiaries) AS avg_beneficiaries
FROM beneficiary_partner_data
GROUP BY village;

#Partners serving more than 5000 beneficiaries
SELECT 
    partner,
    SUM(beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner
HAVING SUM(beneficiaries) > 5000;

#villages with multiple partners
SELECT 
    village,
    COUNT(DISTINCT partner) AS partners
FROM beneficiary_partner_data
GROUP BY village
HAVING COUNT(DISTINCT partner) > 1;

## 2.Joins and combined queries
#Coverage per village(coverage = beneficiaries / total_population)
SELECT 
    b.village,
    v.total_population,
    SUM(b.beneficiaries) AS total_beneficiaries,
    SUM(b.beneficiaries) / v.total_population AS coverage
FROM beneficiary_partner_data b
INNER JOIN village_locations v
ON b.village = v.village
GROUP BY b.village, v.total_population;


#Village and partners (including villages with no partners)
SELECT village, partner
FROM beneficiary_partner_data

UNION

SELECT village, NULL AS partner
FROM village_locations;

##3.Nested Queries / Subqueries

#Villages where coverage is above average
SELECT village
FROM (
    SELECT 
        b.village,
        SUM(b.beneficiaries)/v.total_population AS coverage
    FROM beneficiary_partner_data b
    JOIN village_locations v
    ON b.village = v.village
    GROUP BY b.village, v.total_population
) AS village_coverage
WHERE coverage > (
    SELECT AVG(coverage)
    FROM (
        SELECT 
            SUM(b.beneficiaries)/v.total_population AS coverage
        FROM beneficiary_partner_data b
        JOIN village_locations v
        ON b.village = v.village
        GROUP BY b.village, v.total_population
    ) AS avg_cov
);

#Partners above average beneficiaries
SELECT partner
FROM beneficiary_partner_data
GROUP BY partner
HAVING SUM(beneficiaries) >
(
    SELECT AVG(total_beneficiaries)
    FROM (
        SELECT SUM(beneficiaries) AS total_beneficiaries
        FROM beneficiary_partner_data
        GROUP BY partner
    ) AS partner_totals
);

##4.CTEs 
#District Summaries

WITH district_summary AS
(
    SELECT 
        j.parent AS district,
        SUM(b.beneficiaries) AS total_beneficiaries,
        SUM(v.total_population) AS total_population
    FROM beneficiary_partner_data b
    JOIN village_locations v ON b.village = v.village
    JOIN jurisdiction_hierarchy j ON v.village = j.name
    GROUP BY j.parent
)

SELECT 
    district,
    total_beneficiaries,
    total_population,
    total_beneficiaries/total_population AS coverage
FROM district_summary;

##5.Window Functions
SELECT 
    partner,
    SUM(beneficiaries) AS total_beneficiaries,
    RANK() OVER (ORDER BY SUM(beneficiaries) DESC) AS partner_rank
FROM beneficiary_partner_data
GROUP BY partner;


#Top partner per village
SELECT *
FROM
(
    SELECT 
        partner,
        village,
        beneficiaries,
        ROW_NUMBER() OVER(
            PARTITION BY village
            ORDER BY beneficiaries DESC
        ) AS rn
    FROM beneficiary_partner_data
) ranked
WHERE rn = 1;

##6.Views
#district summary view
CREATE VIEW district_summary AS
SELECT 
    j.parent AS district,
    SUM(b.beneficiaries) AS total_beneficiaries,
    SUM(v.total_population) AS total_population
FROM beneficiary_partner_data b
JOIN village_locations v ON b.village = v.village
JOIN jurisdiction_hierarchy j ON v.village = j.name
GROUP BY j.parent;

SELECT * FROM district_summary;


#partner summary view
CREATE VIEW partner_summary AS
SELECT 
    partner,
    COUNT(DISTINCT village) AS villages_served,
    SUM(beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner;

SELECT * FROM partner_summary;
##7. Triggers
DELIMITER //
CREATE TRIGGER prevent_negative_beneficiaries
BEFORE INSERT ON beneficiary_partner_data
FOR EACH ROW
BEGIN
    IF NEW.beneficiaries < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Beneficiaries cannot be negative';
    END IF;
END;



##Stored Procedures
#perter report
DELIMITER //

CREATE PROCEDURE GetPartnerReport(IN partner_name VARCHAR(30))
BEGIN

SELECT 
    partner,
    COUNT(DISTINCT village) AS villages_served,
    SUM(beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data
WHERE partner = partner_name
GROUP BY partner;

END //

DELIMITER ;

CALL GetPartnerReport('IRC');


##BONUS
#Partners in more than 3 villages
SELECT partner
FROM beneficiary_partner_data
GROUP BY partner
HAVING COUNT(DISTINCT village) > 3;

