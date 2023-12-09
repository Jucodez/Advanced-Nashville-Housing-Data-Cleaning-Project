# Nashville Housing Data Cleaning Project

## Problem Statement

Data has been collected on various real estate transactions in Nashville. This data has had little to no processing carried out on it and needs to be cleaned so it can be used for analysis of real estate in Nashville.

It is your job to ensure that this data set is cleaned up and transformed to a point where it can be taken to various data analytics tools for further preprocessing and subsequent analysis.

## Steps followed 

- Load data from Microsoft Excel to Microsoft SQL Server Management Studio (SSMS) using MS Server Integration Services (SSIS).
- Explore the Dataset and check for null values.
- Fill in missing data in the Property Address column using Property Address entries with the same Parcel ID.
- Ensure Sale Date entries are in the proper format and within the range entries. Then, extract the month and year from each entry.
- Replace Y and N with Yes and No in the Sold As Vacant column for better data consistency.
- Fill in missing data in the Owner Address column using Property Address entries with the same Parcel ID.
- Replace Total Value entries with (land value + building value) to eliminate data inconsistencies.
- Use statistical methods to examine other numerical columns for incorrect entries.
- Remove duplicate values from columns using CTEs and Windows Functions.
- Remove unwanted columns


