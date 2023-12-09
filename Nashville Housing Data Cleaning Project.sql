USE DataCleaningProject;

--------------------------------------------------- Exploring Dataset-----------------------------------------------------------------

SELECT * 
FROM NashvilleHousing;

-- Unique ID column contains a trailing space. This is rectified below

EXEC sp_rename 'NashvilleHousing.[UniqueID ]', 'UniqueID', 'COLUMN';

-- Convert datetime data type to date to eliminate unnecessary time component from SaleDate

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE;

--------------------------------------------------- Examining null values-------------------------------------------------------------

DECLARE @TableName NVARCHAR(255) = 'NashvilleHousing';

DECLARE @SqlQuery NVARCHAR(MAX);

SET @SqlQuery = (
    SELECT 
        'SELECT ''' + COLUMN_NAME + ''' AS ColumnName, COUNT(*) AS NullCount FROM ' + @TableName + ' WHERE [' + COLUMN_NAME + '] IS NULL UNION ALL '
    FROM 
        INFORMATION_SCHEMA.COLUMNS 
    WHERE 
        TABLE_NAME = @TableName
    FOR XML PATH('')
);

SET @SqlQuery = LEFT(@SqlQuery, LEN(@SqlQuery) - 10);

EXEC sp_executesql @SqlQuery;

-- UniqueID, ParcelID, and LandUse don't contain null values

-- examining unique values in LandUse to check for errors

SELECT DISTINCT LandUse
FROM NashvilleHousing;

-- non-detected


------------------------------------ Examining PropertyAddress ----------------------------------------------------------------------

-- Remove excess spaces in property address column

UPDATE NashvilleHousing
SET PropertyAddress = REPLACE(PropertyAddress, '  ', ' ');

UPDATE NashvilleHousing
SET PropertyAddress = LTRIM(RTRIM(PropertyAddress));

-- For the purpose of this project, the street address portion of an address is of little importance 

-- check for repeated parcel ID

SELECT ParcelID, COUNT(ParcelID) AS counts
FROM NashvilleHousing
GROUP BY ParcelID
HAVING COUNT(ParcelID) > 1;

-- Checking that a Parcel ID should have the same Property city address 

SELECT *
FROM NashvilleHousing t1
JOIN NashvilleHousing t2 ON t1.ParcelID = t2.ParcelID AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NOT NULL
AND t2.PropertyAddress IS NOT NULL
AND SUBSTRING(t1.PropertyAddress, CHARINDEX(',', t1.PropertyAddress) + 2, LEN(t1.PropertyAddress)) 
<> SUBSTRING(t2.PropertyAddress, CHARINDEX(',', t2.PropertyAddress) + 2, LEN(t2.PropertyAddress));

-- correct error

UPDATE NashvilleHousing
SET PropertyAddress = '231 5TH AVE N, NASHVILLE'
WHERE PropertyAddress = '0 5TH AVE N, UNKNOWN';

-- replace null Property address entries with not null property address entries with the same parcel ID

UPDATE t1
SET PropertyAddress = t2.PropertyAddress
FROM NashvilleHousing AS t1 
JOIN NashvilleHousing AS t2 ON t1.ParcelID = t2.ParcelID
WHERE t1.PropertyAddress IS NULL 
AND t2.PropertyAddress IS NOT NULL;

-- check for null values

SELECT COUNT(PropertyAddress)
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

--Extract city from property address

ALTER TABLE NashvilleHousing
ADD City NVARCHAR(255);

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress));

--check results

SELECT DISTINCT City
FROM NashvilleHousing;

SELECT *
FROM NashvilleHousing
WHERE City IS NULL;


------------------------------------ Examining SaleDate ---------------------------------------------------------------------

-- Ensuring standardized date format

SELECT SaleDate
FROM NashvilleHousing
WHERE SaleDate IS NOT NULL
      AND SaleDate <> FORMAT(SaleDate, 'yyyy-MM-dd');


-- Ensuring no incorrect date entries

SELECT MAX(SaleDate)
FROM NashvilleHousing;

SELECT MIN(SaleDate)
FROM NashvilleHousing;

-- Extract year and month from SaleDate column

ALTER TABLE NashvilleHousing
ADD SaleYear INT,
    SaleMonth NVARCHAR(20);

UPDATE NashvilleHousing
SET SaleYear = YEAR(SaleDate),
    SaleMonth = DATENAME(MONTH, SaleDate);
  

--Check results

SELECT DISTINCT SaleYear
FROM NashvilleHousing;

SELECT DISTINCT SaleMonth
FROM NashvilleHousing;


------------------------------------ Examining SalePrice ---------------------------------------------------------------------

-- Ensuring no incorrect price entries

SELECT MAX(SalePrice)
FROM NashvilleHousing;

SELECT MIN(SalePrice)
FROM NashvilleHousing;

--Examining max and min sale prices for errors

SELECT *
FROM NashvilleHousing
WHERE SalePrice = 54278060;

SELECT *
FROM NashvilleHousing
WHERE SalePrice = 50;


------------------------------------ Examining SoldAsVacant ---------------------------------------------------------------------

-- examining unique values in SoldAsVacant to check for errors

SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing;

-- check which values are more common to determine the standard value

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;

-- Replace Y and N with Yes and No

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;



------------------------------------ Examining OwnerAddress ---------------------------------------------------------------------

-- Remove excess spaces in property address column

UPDATE NashvilleHousing
SET OwnerAddress = REPLACE(OwnerAddress, '  ', ' ');

UPDATE NashvilleHousing
SET OwnerAddress = LTRIM(RTRIM(OwnerAddress));

-- For the purpose of this project, the street address portion of an address is of little importance 

-- checking if null entries have some parcelids in common with certain not null entries to facilitate replacement

SELECT ParcelID, OwnerAddress
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL
  AND ParcelID IN (SELECT ParcelID FROM NashvilleHousing WHERE OwnerAddress IS NULL);

-- This is not the case, so another method to fill missing data would be investigated

-- checking if property address is same with street and city address element of owner address

SELECT Propertyaddress, SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - 1)
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL 
AND PropertyAddress <>  SUBSTRING(OwnerAddress, 1, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - 1);

-- only minor differences in street address for entries observed

-- confirming that property city  and owner city are same 

SELECT *
FROM NashvilleHousing
WHERE OwnerAddress IS NOT NULL 
AND City <>  LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2));

-- discrepancy observed 
-- 5180 FRANKLIN PIKE CIR, BRENTWOOD (PropertyAddress) and 5180 FRANKLIN PIKE CIR, NASHVILLE, TN (PropertyAddress)
-- an internet search revealed that the property address was right

UPDATE NashvilleHousing
SET OwnerAddress = '5180 FRANKLIN PIKE CIR, BRENTWOOD, TN'
WHERE OwnerAddress = '5180 FRANKLIN PIKE CIR, NASHVILLE, TN';

-- replace missing OwnerAddress values with corresponding PropertyAddress values

UPDATE NashvilleHousing
SET OwnerAddress = ISNULL(OwnerAddress, PropertyAddress + ', TN');

SELECT OwnerAddress
FROM NashvilleHousing;

-- Extract owner address city and state to another column

SELECT DISTINCT RTRIM(LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)))
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerAddressCity NVARCHAR (50);

UPDATE NashvilleHousing
SET OwnerAddressCity = RTRIM(LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)));

SELECT DISTINCT OwnerAddressCity
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD OwnerAddressState NVARCHAR (50);

UPDATE NashvilleHousing
SET OwnerAddressState = RTRIM(LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)));

SELECT DISTINCT OwnerAddressState
FROM NashvilleHousing;



------------------------------------ Examining Acreage ---------------------------------------------------------------------
-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE Acreage IS NULL; 

-- null values appear to correspond with null values in other columns (from tax district -- totalvalue) from initial null value analysis
-- this showed they had the same number of null values
-- most likely a data collection issue

--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE Acreage IN 
(SELECT TOP (10) Acreage
FROM NashvilleHousing
WHERE Acreage IS NOT NULL
ORDER BY Acreage DESC)
ORDER BY Acreage DESC;


--checking lowest values
SELECT *
FROM NashvilleHousing
WHERE Acreage IN 
(SELECT TOP (10) Acreage
FROM NashvilleHousing
WHERE Acreage IS NOT NULL
ORDER BY Acreage)
ORDER BY Acreage;


------------------------------------ Examining LandValue ---------------------------------------------------------------------

-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE LandValue IS NULL; 

--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE LandValue IN 
(SELECT TOP (10) LandValue
FROM NashvilleHousing
WHERE LandValue IS NOT NULL
ORDER BY LandValue DESC);


SELECT *
FROM NashvilleHousing
WHERE LandValue IN 
(SELECT TOP (10) LandValue
FROM NashvilleHousing
WHERE LandValue IS NOT NULL
ORDER BY LandValue);


------------------------------------ Examining BuildingValue ---------------------------------------------------------------------


-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE BuildingValue IS NULL; 

--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE BuildingValue IN 
(SELECT TOP (10) BuildingValue
FROM NashvilleHousing
WHERE BuildingValue IS NOT NULL
ORDER BY BuildingValue DESC)
ORDER BY BuildingValue DESC;

--checking lowest values
SELECT *
FROM NashvilleHousing
WHERE BuildingValue IN 
(SELECT TOP (10) BuildingValue
FROM NashvilleHousing
WHERE BuildingValue IS NOT NULL
ORDER BY BuildingValue) 
ORDER BY BuildingValue;

-- From investigating certain addresses on the internet, it has been confirmed that a BuildingValue of zero indicates no building on the land

SELECT *
FROM NashvilleHousing
WHERE BuildingValue IN 
(SELECT TOP (10) BuildingValue
FROM NashvilleHousing
WHERE BuildingValue IS NOT NULL AND BuildingValue <> 0
ORDER BY BuildingValue) 
ORDER BY BuildingValue;



------------------------------------ Examining TotalValue ---------------------------------------------------------------------

-- investigating null values 

SELECT *
FROM NashvilleHousing
WHERE TotalValue IS NULL; 

-- Investigating Column
SELECT *
FROM NashvilleHousing;

-- checking for discrepancy between total value recorded and (land value + building value)

SELECT LandValue, BuildingValue, TotalValue, TotalValue - (LandValue + BuildingValue) AS Differences
FROM NashvilleHousing
WHERE TotalValue <> (LandValue + BuildingValue)
ORDER BY Differences DESC;

-- Assuming total value = (land value + building value), these errors would be corrected

UPDATE NashvilleHousing
SET TotalValue = (LandValue + BuildingValue);

SELECT LandValue, BuildingValue, TotalValue
FROM NashvilleHousing;



--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE TotalValue IN 
(SELECT TOP (10) TotalValue
FROM NashvilleHousing
WHERE TotalValue IS NOT NULL
ORDER BY TotalValue DESC)
ORDER BY TotalValue DESC;


SELECT *
FROM NashvilleHousing
WHERE TotalValue IN 
(SELECT TOP (10) TotalValue
FROM NashvilleHousing
WHERE TotalValue IS NOT NULL
ORDER BY TotalValue)
ORDER BY TotalValue;



------------------------------------ Examining YearBuilt ---------------------------------------------------------------------

-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE YearBuilt IS NULL AND BuildingValue IS NOT NULL;

SELECT DISTINCT BuildingValue
FROM NashvilleHousing
WHERE YearBuilt IS NULL AND BuildingValue IS NOT NULL;

-- Analysis shows that null values in year built correspond to either missing values due to the presumed data collection issues and also when no building is on the land



--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE YearBuilt IN 
(SELECT TOP (10) YearBuilt
FROM NashvilleHousing
WHERE YearBuilt IS NOT NULL
ORDER BY YearBuilt DESC)
ORDER BY YearBuilt DESC;

SELECT *
FROM NashvilleHousing
WHERE YearBuilt IN 
(SELECT TOP (10) YearBuilt
FROM NashvilleHousing
WHERE YearBuilt IS NOT NULL
ORDER BY YearBuilt)
ORDER BY YearBuilt;




------------------------------------ Examining Bedrooms ---------------------------------------------------------------------

-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE Bedrooms IS NULL AND (BuildingValue IS NOT NULL AND BuildingValue <> 0);

-- only 18 null entries for Bedrooms when Building value was null or 0.

-- checking to see if the number of bedrooms can be replaced by the number of full bathrooms

SELECT *
FROM NashvilleHousing
WHERE Bedrooms = FullBath AND Bedrooms IS NOT NULL AND Bedrooms <>0 AND FullBath IS NOT NULL AND FullBath <>0;

SELECT *
FROM NashvilleHousing
WHERE Bedrooms IS NULL AND FullBath IS NOT NULL AND FullBath <>0;

-- This is not possible as there are only a few entries with the same number of Bedrooms and FullBath indicating they are not the same




--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE Bedrooms IN 
(SELECT TOP (10) Bedrooms
FROM NashvilleHousing
WHERE Bedrooms IS NOT NULL
ORDER BY Bedrooms DESC)
ORDER BY Bedrooms DESC;

-- checking lowest values

SELECT *
FROM NashvilleHousing
WHERE Bedrooms IN 
(SELECT TOP (10) Bedrooms
FROM NashvilleHousing
WHERE Bedrooms IS NOT NULL 
ORDER BY Bedrooms)
ORDER BY Bedrooms;


------------------------------------ Examining FullBath ---------------------------------------------------------------------

-- investigating null values
SELECT *
FROM NashvilleHousing
WHERE FullBath IS NULL AND (BuildingValue IS NOT NULL AND BuildingValue <> 0);

-- only 3 null entries for FullBath when Building value was null or 0.

--checking highest values 
SELECT *
FROM NashvilleHousing
WHERE FullBath IN 
(SELECT TOP (10) FullBath
FROM NashvilleHousing
WHERE FullBath IS NOT NULL
ORDER BY FullBath DESC)
ORDER BY FullBath DESC;

-- checking lowest values

SELECT *
FROM NashvilleHousing
WHERE FullBath IN 
(SELECT TOP (10) FullBath
FROM NashvilleHousing
WHERE FullBath IS NOT NULL 
ORDER BY FullBath)
ORDER BY FullBath;



-------------------------------------- Examining HalfBath -------------------------------------------

-- Investigating null values
SELECT *
FROM NashvilleHousing
WHERE HalfBath IS NULL AND (BuildingValue IS NOT NULL AND BuildingValue <> 0);

-- Only 134 null entries for HalfBath when Building value was null or 0.

-- Checking highest values 
SELECT *
FROM NashvilleHousing
WHERE HalfBath IN 
(SELECT TOP (10) HalfBath
 FROM NashvilleHousing
 WHERE HalfBath IS NOT NULL
 ORDER BY HalfBath DESC)
ORDER BY HalfBath DESC;

-- Checking lowest values
SELECT *
FROM NashvilleHousing
WHERE HalfBath IN 
(SELECT TOP (10) HalfBath
 FROM NashvilleHousing
 WHERE HalfBath IS NOT NULL 
 ORDER BY HalfBath)
ORDER BY HalfBath;

-------------------------------------- Remove duplicates -------------------------------------------

-- Check for duplicate rows based on certain columns
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                             ORDER BY UniqueID) AS row_num
    FROM NashvilleHousing
    -- ORDER BY ParcelID
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Remove duplicates
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                             ORDER BY UniqueID) AS row_num
    FROM NashvilleHousing
    -- ORDER BY ParcelID
)

DELETE
FROM RowNumCTE
WHERE row_num > 1;

-- ------------------------------------ Remove unused columns -------------------------------------------

SELECT *
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
DROP COLUMN TaxDistrict, SaleDate, TotalValue2, OwnerAddress2;

