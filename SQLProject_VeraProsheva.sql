--Create DB

CREATE DATABASE SQLProject_VeraProsheva
GO

USE SQLProject_VeraProsheva
GO

--Create tables 

CREATE TABLE dbo.SeniorityLevel (
Id int IDENTITY(1,1) not null,
[Name] nvarchar(100) not null,
	CONSTRAINT PK_SeniorityLevel PRIMARY KEY CLUSTERED 
	(Id ASC)
)
GO

CREATE TABLE dbo.[Location] (
Id int IDENTITY(1,1) not null,
CountryName nvarchar(100) null,
Continent nvarchar(100) null,
Region nvarchar(100) null,
	CONSTRAINT PK_Location PRIMARY KEY CLUSTERED 
	(Id ASC)
)
GO

CREATE TABLE dbo.Department (
Id int IDENTITY(1,1) not null,
[Name] nvarchar(100) not null,
	CONSTRAINT PK_Department PRIMARY KEY CLUSTERED 
	(Id ASC)
)
GO

CREATE TABLE dbo.Employee (
Id int IDENTITY(1,1) not null,
FirstName nvarchar(100) not null,
LastName nvarchar(100) not null,
LocationId int not null,
SeniorityLevelId int not null,
DepartmentId int not null,
	CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED 
	(Id ASC)
)
GO

CREATE TABLE dbo.Salary (
Id int IDENTITY(1,1) not null,
EmployeeId int not null,
[Month] smallint not null,
[Year] smallint not null,
GrossAmount decimal(18,2) not null,
NetAmount decimal(18,2) not null,
RegularWorkAmount decimal(18,2) not null,
BonusAmount decimal(18,2) not null,
OvertimeAmount decimal(18,2) not null,
VacationDays smallint not null,
SickLeaveDays smallint not null,
	CONSTRAINT PK_Id PRIMARY KEY CLUSTERED 
	(Id ASC)
)
GO

--Create constraints between tables

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Employee_Location FOREIGN KEY (LocationId)
REFERENCES dbo.[Location] (Id)
GO

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Employee_SeniorityLevel FOREIGN KEY (SeniorityLevelId)
REFERENCES dbo.SeniorityLevel (Id)
GO

ALTER TABLE dbo.Employee
ADD CONSTRAINT FK_Employee_Department FOREIGN KEY (DepartmentId)
REFERENCES dbo.Department (Id)
GO

ALTER TABLE dbo.Salary
ADD CONSTRAINT FK_Salary_Employee FOREIGN KEY (EmployeeId)
REFERENCES dbo.Employee (Id)
GO

--Insert data into tables
--dbo.SeniorityLevel

INSERT INTO dbo.SeniorityLevel ([Name])
VALUES ('Junior'),
	   ('Intermediate'),
	   ('Senior'),
	   ('Lead'),
	   ('Project Manager'),
	   ('Division Manager'),
	   ('Office Manager'),
	   ('CEO'),
	   ('CTO'),
	   ('CIO')
GO

--dbo.Location

INSERT INTO dbo.[Location] ([CountryName], [Continent], [Region])
SELECT CountryName, 
       Continent, 
	   Region
FROM WideWorldImporters.Application.Countries
GO

--dbo.Department

INSERT INTO dbo.Department ([Name])
VALUES ('Personal Banking & Operations'),
	   ('Digital Banking Department'),
	   ('Retail Banking & Marketing Department'),
	   ('Wealth Management & Third Party Products'),
	   ('International Banking Division & DFB'),
	   ('Treasury'),
	   ('Information Technology'),
	   ('Corporate Communications'),
	   ('Support Services & Branch Expansion'),
	   ('Human Resources')
GO

--dbo.Employee

INSERT INTO dbo.Employee ([FirstName], [LastName], [LocationId], [SeniorityLevelId], [DepartmentId])
SELECT  LEFT(FullName, charindex(' ', FullName) - 1) as FirstName,
        RIGHT(FullName, charindex(' ', (REVERSE(FullName))) - 1) as LastName,
        ((ROW_NUMBER() OVER (ORDER BY PersonId) - 1) / 6) + 1 as LocationId,
		NTILE(10) OVER (ORDER BY PersonId) as SeniorityLevelId,
		NTILE(10) OVER (ORDER BY PersonId) as DepartmentId
FROM WideWorldImporters.Application.People
WHERE FullName != 'Data Conversion Only'
GO

--dbo.Salary
--Create temp tables to populate data for the past 20 years

CREATE TABLE #MonthTemp ([Month] int)
GO

INSERT INTO #MonthTemp ([Month])
values (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)
GO

CREATE TABLE #YearTemp ([Year] int)
GO 

;WITH cte AS (
    SELECT 2001 AS [Year]
    UNION ALL
    SELECT [Year] + 1
    FROM cte
    WHERE [Year] < 2020
)
INSERT INTO #YearTemp ([Year])
SELECT [Year] FROM cte
GO

--Insert into dbo.Salary

INSERT INTO dbo.Salary ([EmployeeId], [Month], [Year], [GrossAmount], [NetAmount], [RegularWorkAmount], [BonusAmount], [OvertimeAmount], [VacationDays], [SickLeaveDays])
SELECT e.Id,
       mt.[Month],
	   yt.[Year],
	   FLOOR((ABS(CHECKSUM(NEWID())) % (60000 - 30000 + 1)) + 30000),
	   0,
	   0,
	   0,
	   0,
	   0,
	   0
FROM dbo.Employee as e
CROSS JOIN #MonthTemp as mt
CROSS JOIN #YearTemp as yt
GROUP BY e.Id, mt.[Month], yt.[Year]
ORDER BY yt.[Year] ASC
GO

--Set Net Amount to be 90% of the gross amount

UPDATE dbo.Salary
SET NetAmount = GrossAmount * 0.9
GO

--Set RegularWorkAmount to be 80% of the total Net amount for all employees and months

UPDATE dbo.Salary
SET RegularWorkAmount = NetAmount * 0.8
GO

--Set Bonus amount to be the difference between the NetAmount and RegularWorkAmount for every Odd month (January,March,..)

UPDATE dbo.Salary
SET BonusAmount = NetAmount - RegularWorkAmount
WHERE [Month] in (1,3,5,7,9,11)
GO

--Set OvertimeAmount to be the difference between the NetAmount and RegularWorkAmount for every Even month (February,April,…)

UPDATE dbo.Salary
SET OvertimeAmount = NetAmount -  RegularWorkAmount
WHERE [Month] in (2,4,6,8,10,12)
GO

--All employees use 10 vacation days in July and 10 Vacation days in December

UPDATE dbo.Salary
SET VacationDays = 10 
WHERE [Month] in (7,12)
GO

--Additionally random vacation days and sickLeaveDays are generated with the following script

UPDATE dbo.Salary 
SET VacationDays = VacationDays + (EmployeeId % 2)
WHERE (EmployeeId + MONTH+ year)%5 = 1
GO

UPDATE dbo.Salary 
SET SickLeaveDays = EmployeeId%8, VacationDays = VacationDays + (EmployeeId % 3)
WHERE (EmployeeId + MONTH+ year)%5 = 2
GO

--Check (should return 0)
SELECT * 
FROM dbo.Salary 
WHERE NetAmount <> (RegularWorkAmount + BonusAmount + OverTimeAmount)

--Additionally, vacation days should be between 20 and 30

UPDATE dbo.Salary
SET VacationDays = FLOOR((ABS(CHECKSUM(NEWID())) % (30 - 20 + 1)) + 20)
WHERE VacationDays <> 0
GO

--Final Check
SELECT * FROM dbo.SeniorityLevel
SELECT * FROM dbo.[Location]
SELECT * FROM dbo.Department
SELECT * FROM dbo.Employee
SELECT * FROM dbo.Salary

