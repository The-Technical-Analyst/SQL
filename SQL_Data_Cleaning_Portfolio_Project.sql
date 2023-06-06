SELECT OwnerName, OwnerAddress
FROM Data_Cleaning_Projects..Nashville_Housing_Data
--WHERE OwnerName is not null AND OwnerAddress is not null

--Standardized Date Format
SELECT SaleDate, CONVERT(Date,SaleDate)
FROM Data_Cleaning_Projects..Nashville_Housing_Data

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD SaleDateConverted Date;

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted
FROM Data_Cleaning_Projects..Nashville_Housing_Data


--Populate Property Address Data
SELECT Nash.PropertyAddress, nash.ParcelID, Ville.PropertyAddress, Ville.ParcelID, ISNULL(Nash.PropertyAddress,Ville.PropertyAddress)
FROM Data_Cleaning_Projects..Nashville_Housing_Data AS Nash
JOIN Data_Cleaning_Projects..Nashville_Housing_Data AS Ville
ON Nash.ParcelID = Ville.ParcelID
AND Nash.[UniqueID ] <> Ville.[UniqueID ]
WHERE Nash.PropertyAddress is null
ORDER BY Nash.ParcelID

UPDATE Nash
SET PropertyAddress = ISNULL(Nash.PropertyAddress,Ville.PropertyAddress)
FROM Data_Cleaning_Projects..Nashville_Housing_Data AS Nash
JOIN Data_Cleaning_Projects..Nashville_Housing_Data AS Ville
ON Nash.ParcelID = Ville.ParcelID
AND Nash.[UniqueID ] <> Ville.[UniqueID ]
WHERE Nash.PropertyAddress is null

SELECT PropertyAddress
FROM Data_Cleaning_Projects..Nashville_Housing_Data
WHERE PropertyAddress is null

---Sepeating Address into Address & City----
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PROPERTY_ADDRESS,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS PROPERTY_CITY
FROM Data_Cleaning_Projects..Nashville_Housing_Data
--WHERE PropertyAddress is null

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD PROPERTY_ADDRESS NVARCHAR(255);

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET PROPERTY_ADDRESS = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD PROPERTY_CITY NVARCHAR(255);

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET PROPERTY_CITY  = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM Data_Cleaning_Projects..Nashville_Housing_Data

--- For Owner Address---
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OWNER_ADDRESS,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OWNER_CITY,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OWNER_STATE
FROM Data_Cleaning_Projects..Nashville_Housing_Data

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD OWNER_ADDRESS NVARCHAR(255);

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET OWNER_ADDRESS = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD OWNER_CITY NVARCHAR(255);

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET OWNER_CITY = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
ADD OWNER_STATE NVARCHAR(255);

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET OWNER_STATE = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


--Updating 'Y' & 'N' to 'YES' & 'NO'
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Data_Cleaning_Projects..Nashville_Housing_Data
GROUP BY SoldAsVacant
ORDER BY  2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM Data_Cleaning_Projects..Nashville_Housing_Data

UPDATE Data_Cleaning_Projects..Nashville_Housing_Data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

--Removing Duplicates----
WITH RowNumCTE AS 
(
SELECT *,
ROW_NUMBER() 
OVER (
PARTITION BY ParcelID, SalePrice, SaleDate, LegalReference
ORDER BY UniqueID 
) AS ROW_NUM
FROM Data_Cleaning_Projects..Nashville_Housing_Data
)
SELECT *
FROM RowNumCTE
WHERE ROW_NUM > 1

--Delete Unused Columns-----
SELECT *
FROM Data_Cleaning_Projects..Nashville_Housing_Data

ALTER TABLE Data_Cleaning_Projects..Nashville_Housing_Data
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict










