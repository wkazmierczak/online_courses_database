USE [master]
GO
/****** Object:  Database [u_stylski]    Script Date: 22/01/2024 12:42:37 ******/
CREATE DATABASE [u_stylski]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'u_stylski', FILENAME = N'/var/opt/mssql/data/u_stylski.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'u_stylski_log', FILENAME = N'/var/opt/mssql/data/u_stylski_log.ldf' , SIZE = 66048KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [u_stylski] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [u_stylski].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [u_stylski] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [u_stylski] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [u_stylski] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [u_stylski] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [u_stylski] SET ARITHABORT OFF 
GO
ALTER DATABASE [u_stylski] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [u_stylski] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [u_stylski] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [u_stylski] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [u_stylski] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [u_stylski] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [u_stylski] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [u_stylski] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [u_stylski] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [u_stylski] SET  ENABLE_BROKER 
GO
ALTER DATABASE [u_stylski] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [u_stylski] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [u_stylski] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [u_stylski] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [u_stylski] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [u_stylski] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [u_stylski] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [u_stylski] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [u_stylski] SET  MULTI_USER 
GO
ALTER DATABASE [u_stylski] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [u_stylski] SET DB_CHAINING OFF 
GO
ALTER DATABASE [u_stylski] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [u_stylski] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [u_stylski] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [u_stylski] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [u_stylski] SET QUERY_STORE = OFF
GO
USE [u_stylski]
GO
/****** Object:  DatabaseRole [tutor]    Script Date: 22/01/2024 12:42:38 ******/
CREATE ROLE [tutor]
GO
/****** Object:  DatabaseRole [not_logged_in_user]    Script Date: 22/01/2024 12:42:38 ******/
CREATE ROLE [not_logged_in_user]
GO
/****** Object:  DatabaseRole [logged_in_user]    Script Date: 22/01/2024 12:42:38 ******/
CREATE ROLE [logged_in_user]
GO
/****** Object:  DatabaseRole [headmaster]    Script Date: 22/01/2024 12:42:39 ******/
CREATE ROLE [headmaster]
GO
/****** Object:  DatabaseRole [course_coordinator]    Script Date: 22/01/2024 12:42:39 ******/
CREATE ROLE [course_coordinator]
GO
/****** Object:  DatabaseRole [admin]    Script Date: 22/01/2024 12:42:39 ******/
CREATE ROLE [admin]
GO
/****** Object:  UserDefinedFunction [dbo].[AvgGradeFromExam]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[AvgGradeFromExam](@given_exam_id INT)
RETURNS INT
AS
BEGIN
	return( select avg(grade) from ExamDetails
	where ExamId = @given_exam_id
	Group by ExamId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[AvgIncome]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----2 TODO
CREATE FUNCTION [dbo].[AvgIncome]()
RETURNS MONEY
AS
BEGIN
	RETURN (select avg(total_amount) from 
	(SELECT sum(amount) as total_amount
	from Payments as p
	INNER JOIN PaymentDetails as pd
	ON p.PaymentId=pd.PaymentId
	Group by YEAR(Date), MONTH(Date)) as sums)
END
GO
/****** Object:  UserDefinedFunction [dbo].[DidClientPass]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DidClientPass](@StudentId int, @ServiceId int)
RETURNS INT
AS
BEGIN

    DECLARE @StudentAttendance tinyint
    SET @StudentAttendance = [dbo].StudentAttendance(@StudentId, @ServiceId)

	DECLARE @AttendancePass INT
    SET @AttendancePass = [dbo].IsAttendanceEnough(@StudentAttendance, @ServiceId)
	IF @AttendancePass = 0
	BEGIN
		RETURN 0
	END
	
	DECLARE @ExamId int
    SET @ExamId = (SELECT ExamId FROM Services WHERE ServiceId = @ServiceId)
	
	IF @ExamId IS NULL
	BEGIN
		RETURN 1
	END

	DECLARE @ExamGrade FLOAT
    SET @ExamGrade = (
		SELECT Grade 
		FROM ExamDetails exd
		INNER JOIN Exams ex ON ex.ExamId = exd.ExamId
		INNER JOIN Services ser On ser.ExamId = ex.ExamId
		WHERE ClientId = @StudentId AND ser.ServiceId = @ServiceId
		)

	IF @ExamGrade > 2.0
	BEGIN
		RETURN 1
	END
	RETURN 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[IncomeFromCourse]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IncomeFromCourse]( @courseid Int
)
RETURNS INT
AS
BEGIN
	RETURN (SELECT sum(ModulePrice) From Modules
	Where ServiceId = @courseid
	Group by ServiceId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsAttendanceEnough]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IsAttendanceEnough](@att Tinyint, @service Int)
RETURNS INT
AS
BEGIN
	DECLARE @pass_per TINYINT

	SET @pass_per = (Select PassPercent from Services
	where ServiceId = @service)

	IF @pass_per <= @att
		BEGIN
			RETURN 1
		END
	RETURN 0 
END
GO
/****** Object:  UserDefinedFunction [dbo].[NumOfClients]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[NumOfClients](
)
RETURNS INT
AS
BEGIN
	RETURN (SELECT count(*) From Clients
	Group by ClientId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[NumOFCouresInProgress]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--11
CREATE FUNCTION [dbo].[NumOFCouresInProgress](@curr_date DATE)
RETURNS INT
AS
BEGIN
	return( select count(ServiceId) from Services
	where BeginDate < @curr_date AND @curr_date < EndDate
)
END
GO
/****** Object:  UserDefinedFunction [dbo].[NumOfWorkers]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[NumOfWorkers](
)
RETURNS INT
AS
BEGIN
	RETURN (SELECT count(*) From Workers
	Group by WorkerId)
END
GO
/****** Object:  UserDefinedFunction [dbo].[ServiceFreePlaces]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ServiceFreePlaces](@ServiceId INT)
RETURNS INT
AS
BEGIN
	DECLARE @TotalPlaces INT
    SET @TotalPlaces = (
		SELECT MIN(ClassSize)
		FROM Modules
		WHERE ServiceId = @ServiceId
	)

	DECLARE @AdvancePrice MONEY
    SET @AdvancePrice = (SELECT AdvancePrice FROM Services WHERE ServiceId = @ServiceId)

	DECLARE @TakenPlaces INT
    SET @TakenPlaces = (
		SELECT COUNT(*)
		FROM Payments p
		INNER JOIN PaymentDetails pd ON p.PaymentId = pd.PaymentId
		WHERE p.State = 1 AND pd.ServiceId = @ServiceId
		GROUP BY p.ClientId
		HAVING SUM(pd.Amount - ISNULL(pd.AmountWaived, 0)) >= @AdvancePrice
	)

	RETURN @TotalPlaces - @TakenPlaces
END
GO
/****** Object:  UserDefinedFunction [dbo].[StudentAttendance]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StudentAttendance](@StudentId int, @ServiceId int)
RETURNS TINYINT
AS
BEGIN
    DECLARE @ModulesCount INT
	SET @ModulesCount = (
		SELECT COUNT(*)
		FROM Modules
		WHERE ServiceId = @ServiceId
	)

    DECLARE @ModulesAttended INT
	SET @ModulesAttended = (
		SELECT COUNT(*)
		FROM Modules mod
		INNER JOIN Attendance att ON mod.ModuleId = att.ModuleId
		WHERE att.ClientId = @StudentId
	)

	RETURN @ModulesAttended / @ModulesCount
END
GO
/****** Object:  UserDefinedFunction [dbo].[StudentECTSLoss]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StudentECTSLoss](@StudentId int)
RETURNS int
AS
BEGIN
	RETURN (
		SELECT SUM(sub.ECTS)
		FROM Exams ex
		INNER JOIN ExamDetails exd ON ex.ExamId = exd.ExamId
		INNER JOIN Services ser ON ex.ExamId = ser.ExamId
		INNER JOIN Syllabus syl ON ser.SyllabusId = syl.SyllabusId
		INNER JOIN Subjects sub ON sub.SubjectId = syl.SubjectId
		WHERE exd.ClientId = @StudentId AND exd.Grade = 2.0
	)
END
GO
/****** Object:  UserDefinedFunction [dbo].[StudentRemainingPayments]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[StudentRemainingPayments](@StudentId int)
RETURNS MONEY
AS
BEGIN
	RETURN (
		SELECT SUM(s.ServicePrice) + SUM(m.ModulePrice) - SUM(ISNULL(pd.AmountWaived, 0))
		FROM Payments p 
		INNER JOIN PaymentDetails pd ON p.PaymentId = pd.PaymentId 
		INNER JOIN Services s ON s.ServiceId = pd.ServiceId 
		INNER JOIN Modules m ON m.ModuleId = pd.ModuleId
		WHERE p.ClientId = @StudentId AND p.State = 0
		)
END
GO
/****** Object:  UserDefinedFunction [dbo].[TotalIncome]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TotalIncome]()
RETURNS MONEY
AS
BEGIN
	RETURN (SELECT sum(Amount) From PaymentDetails
	Group by PaymentId)
END
GO
/****** Object:  Table [dbo].[ExamDetails]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExamDetails](
	[ExamId] [int] NOT NULL,
	[ClientId] [int] NOT NULL,
	[Grade] [float] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[DistributionExamsGrades]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[DistributionExamsGrades](@given_exam_id INT)
RETURNS TABLE
AS
RETURN
(
select Grade, COUNT(*) as num_of_grades from ExamDetails
	where ExamId = @given_exam_id
	Group by ExamId, Grade
)
GO
/****** Object:  Table [dbo].[Workers]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Workers](
	[WorkerId] [int] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
	[Role] [tinyint] NOT NULL,
 CONSTRAINT [PK_Workers] PRIMARY KEY CLUSTERED 
(
	[WorkerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkersLanguages]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkersLanguages](
	[WorkerId] [int] NOT NULL,
	[WorkerLanguage] [varchar](2) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[TranslatorsThatCanSpeak]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TranslatorsThatCanSpeak](@given_language VARCHAR)
RETURNS TABLE
AS
RETURN
(
select Name, Surname from WorkersLanguages as wl
	Inner join Workers as w on w.WorkerId = wl.WorkerId
	where WorkerLanguage = @given_language
	Group by WorkerLanguage, Name, Surname
)
GO
/****** Object:  UserDefinedFunction [dbo].[AvailableLanguages]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[AvailableLanguages]()
RETURNS TABLE
AS
RETURN
(
select Distinct(WorkerLanguage) from WorkersLanguages as wl
	Group by WorkerLanguage
)
GO
/****** Object:  Table [dbo].[Services]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Services](
	[ServiceId] [int] NOT NULL,
	[ServiceType] [tinyint] NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[ServicePrice] [money] NOT NULL,
	[AdvancePrice] [money] NOT NULL,
	[SyllabusId] [int] NULL,
	[ExamId] [int] NULL,
	[CoordinatorId] [int] NULL,
	[AccessDate] [date] NULL,
	[PassPercent] [tinyint] NOT NULL,
	[Title] [varchar](50) NOT NULL,
	[Description] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Services] PRIMARY KEY CLUSTERED 
(
	[ServiceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[CouresInProgress]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CouresInProgress](@curr_date DATE)
RETURNS TABLE
AS
return( select ServiceId from Services
where BeginDate < @curr_date AND @curr_date < EndDate
)
GO
/****** Object:  Table [dbo].[Clients]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Clients](
	[ClientId] [int] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
	[Street] [varchar](50) NULL,
	[HomeNumber] [varchar](50) NOT NULL,
	[City] [varchar](50) NOT NULL,
	[Country] [varchar](50) NOT NULL,
	[ZipCode] [varchar](6) NOT NULL,
	[Email] [varchar](50) NOT NULL,
	[Phone] [varchar](11) NOT NULL,
 CONSTRAINT [PK_Clients] PRIMARY KEY CLUSTERED 
(
	[ClientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PaymentDetails]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentDetails](
	[PaymentId] [int] NOT NULL,
	[ServiceId] [int] NULL,
	[ModuleId] [int] NULL,
	[Amount] [money] NOT NULL,
	[AmountWaived] [money] NULL,
	[DaysWaived] [int] NULL,
 CONSTRAINT [PK_PaymentDetails] PRIMARY KEY CLUSTERED 
(
	[PaymentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payments]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payments](
	[PaymentId] [int] NOT NULL,
	[ClientId] [int] NOT NULL,
	[State] [tinyint] NOT NULL,
	[Date] [datetime] NOT NULL,
	[PaymentURL] [varchar](max) NOT NULL,
 CONSTRAINT [PK_Payments] PRIMARY KEY CLUSTERED 
(
	[PaymentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[UnpaidClientsView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UnpaidClientsView] AS
SELECT DISTINCT c.ClientId, c.Name, c.Surname, SUM(Amount - ISNULL(AmountWaived, 0)) AS 'Zaległości'
FROM Payments p
INNER JOIN Clients c ON c.ClientId = p.PaymentId
INNER JOIN PaymentDetails pd ON p.PaymentId = pd.PaymentId
WHERE p.[State] = 0
GROUP BY c.ClientId, c.Name, c.Surname
GO
/****** Object:  Table [dbo].[Modules]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Modules](
	[ModuleId] [int] NOT NULL,
	[ServiceId] [int] NOT NULL,
	[ModuleBeginDate] [datetime] NOT NULL,
	[ModuleEndDate] [datetime] NOT NULL,
	[ModuleType] [tinyint] NOT NULL,
	[Class] [varchar](50) NOT NULL,
	[ClassSize] [tinyint] NOT NULL,
	[URL] [varchar](max) NULL,
	[SubjectId] [int] NOT NULL,
	[LecturerId] [int] NOT NULL,
	[TranslatorId] [int] NULL,
	[Language] [varchar](2) NULL,
	[ModulePrice] [money] NOT NULL,
 CONSTRAINT [PK_Modules] PRIMARY KEY CLUSTERED 
(
	[ModuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[FutureModulesView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[FutureModulesView] AS
SELECT Services.Title,Modules.ModuleBeginDate, Modules.ModuleEndDate,Modules.ModulePrice 
FROM Modules
JOIN Services ON Modules.ServiceId = Services.ServiceId
WHERE Modules.ModuleEndDate >= CURRENT_TIMESTAMP; 

GO
/****** Object:  View [dbo].[AvailableServicesView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AvailableServicesView] AS
SELECT DISTINCT Services.Title,Services.Description, Services.ServiceType ,Services.BeginDate,Services.EndDate,Services.ServicePrice
FROM Services
JOIN Modules ON Services.ServiceId = Modules.ServiceId
WHERE Modules.ModuleEndDate >= CURRENT_TIMESTAMP;

GO
/****** Object:  View [dbo].[WorkersModulesView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[WorkersModulesView] AS
SELECT Workers.WorkerId, Workers.Name, Workers.Surname, Modules.ModuleId
FROM Workers
LEFT JOIN Modules ON Workers.WorkerId = Modules.LecturerId OR Workers.WorkerId = Modules.TranslatorId;
GO
/****** Object:  Table [dbo].[Exams]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exams](
	[ExamId] [int] NOT NULL,
	[Date] [datetime] NULL,
 CONSTRAINT [PK_Exams] PRIMARY KEY CLUSTERED 
(
	[ExamId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[PassedStudentsView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[PassedStudentsView] AS
SELECT Clients.ClientId, Clients.Name,Clients.Surname,ExamDetails.Grade
FROM Clients
JOIN ExamDetails ON Clients.ClientId = ExamDetails.ClientId
JOIN Exams ON ExamDetails.ExamId = Exams.ExamId
WHERE ExamDetails.Grade > 2 ;
GO
/****** Object:  View [dbo].[FailedStudentsView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[FailedStudentsView] AS
SELECT Clients.ClientId, Clients.Name,Clients.Surname,ExamDetails.Grade
FROM Clients
JOIN ExamDetails ON Clients.ClientId = ExamDetails.ClientId
JOIN Exams ON ExamDetails.ExamId = Exams.ExamId
WHERE ExamDetails.Grade = 2 ;

GO
/****** Object:  View [dbo].[ServiceRevenueView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ServiceRevenueView] AS
SELECT Services.ServiceId, Services.Title, COALESCE(SUM(PaymentDetails.Amount), 0) AS TotalRevenue
FROM Services
LEFT JOIN PaymentDetails ON Services.ServiceId = PaymentDetails.ServiceId
GROUP BY Services.ServiceId, Services.Title;

GO
/****** Object:  View [dbo].[ModuleTypeRevenueView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ModuleTypeRevenueView] AS
SELECT Modules.ModuleType, COALESCE(SUM(PaymentDetails.Amount), 0) AS TotalRevenue
FROM Modules
LEFT JOIN PaymentDetails ON Modules.ModuleId = PaymentDetails.ModuleId
GROUP BY Modules.ModuleType;
GO
/****** Object:  View [dbo].[AllStudiesView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AllStudiesView] AS
SELECT Services.ServiceId,Services.BeginDate, Services.EndDate, Services.ServicePrice, Workers.Name AS CoordinatorName, Workers.Surname AS CoordinatorSurname
FROM Services
JOIN Workers ON Services.CoordinatorId = Workers.WorkerId
WHERE Services.ServiceType = 2;
GO
/****** Object:  View [dbo].[AllCoursesView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AllCoursesView] AS
SELECT Services.ServiceId,Services.BeginDate, 
Services.EndDate, 
Services.ServicePrice
FROM Services
WHERE Services.ServiceType = 1;


GO
/****** Object:  View [dbo].[AllWebinarsView]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[AllWebinarsView] AS
SELECT Services.ServiceId,Services.BeginDate, 
Services.EndDate, 
Services.ServicePrice
FROM Services
WHERE Services.ServiceType = 0;


GO
/****** Object:  Table [dbo].[Attendance]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Attendance](
	[ModuleId] [int] NOT NULL,
	[ClientId] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Subjects]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Subjects](
	[SubjectId] [int] NOT NULL,
	[ECTS] [tinyint] NOT NULL,
	[Description] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Subjects] PRIMARY KEY CLUSTERED 
(
	[SubjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Syllabus]    Script Date: 22/01/2024 12:42:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Syllabus](
	[SyllabusId] [int] NOT NULL,
	[SubjectId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Attendance]  WITH CHECK ADD  CONSTRAINT [FK_Attendance_Modules] FOREIGN KEY([ModuleId])
REFERENCES [dbo].[Modules] ([ModuleId])
GO
ALTER TABLE [dbo].[Attendance] CHECK CONSTRAINT [FK_Attendance_Modules]
GO
ALTER TABLE [dbo].[ExamDetails]  WITH CHECK ADD  CONSTRAINT [FK_ExamDetails_Exams] FOREIGN KEY([ExamId])
REFERENCES [dbo].[Exams] ([ExamId])
GO
ALTER TABLE [dbo].[ExamDetails] CHECK CONSTRAINT [FK_ExamDetails_Exams]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [FK_Modules_Services] FOREIGN KEY([ServiceId])
REFERENCES [dbo].[Services] ([ServiceId])
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [FK_Modules_Services]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [FK_Modules_Subjects] FOREIGN KEY([SubjectId])
REFERENCES [dbo].[Subjects] ([SubjectId])
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [FK_Modules_Subjects]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [FK_Modules_Workers_Lecturers] FOREIGN KEY([LecturerId])
REFERENCES [dbo].[Workers] ([WorkerId])
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [FK_Modules_Workers_Lecturers]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [FK_Modules_Workers_Translators] FOREIGN KEY([TranslatorId])
REFERENCES [dbo].[Workers] ([WorkerId])
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [FK_Modules_Workers_Translators]
GO
ALTER TABLE [dbo].[PaymentDetails]  WITH CHECK ADD  CONSTRAINT [FK_PaymentDetails_Modules] FOREIGN KEY([ModuleId])
REFERENCES [dbo].[Modules] ([ModuleId])
GO
ALTER TABLE [dbo].[PaymentDetails] CHECK CONSTRAINT [FK_PaymentDetails_Modules]
GO
ALTER TABLE [dbo].[PaymentDetails]  WITH CHECK ADD  CONSTRAINT [FK_PaymentDetails_Services] FOREIGN KEY([ServiceId])
REFERENCES [dbo].[Services] ([ServiceId])
GO
ALTER TABLE [dbo].[PaymentDetails] CHECK CONSTRAINT [FK_PaymentDetails_Services]
GO
ALTER TABLE [dbo].[Payments]  WITH CHECK ADD  CONSTRAINT [FK_Payments_Clients] FOREIGN KEY([ClientId])
REFERENCES [dbo].[Clients] ([ClientId])
GO
ALTER TABLE [dbo].[Payments] CHECK CONSTRAINT [FK_Payments_Clients]
GO
ALTER TABLE [dbo].[Payments]  WITH CHECK ADD  CONSTRAINT [FK_Payments_PaymentDetails] FOREIGN KEY([PaymentId])
REFERENCES [dbo].[PaymentDetails] ([PaymentId])
GO
ALTER TABLE [dbo].[Payments] CHECK CONSTRAINT [FK_Payments_PaymentDetails]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [FK_Services_Exams] FOREIGN KEY([ExamId])
REFERENCES [dbo].[Exams] ([ExamId])
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [FK_Services_Exams]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [FK_Services_Workers] FOREIGN KEY([CoordinatorId])
REFERENCES [dbo].[Workers] ([WorkerId])
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [FK_Services_Workers]
GO
ALTER TABLE [dbo].[WorkersLanguages]  WITH CHECK ADD  CONSTRAINT [FK_WorkersLanguages_Workers] FOREIGN KEY([WorkerId])
REFERENCES [dbo].[Workers] ([WorkerId])
GO
ALTER TABLE [dbo].[WorkersLanguages] CHECK CONSTRAINT [FK_WorkersLanguages_Workers]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [Phone] CHECK  ((len([Phone])>=(9)))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [Phone]
GO
ALTER TABLE [dbo].[Clients]  WITH CHECK ADD  CONSTRAINT [ZipCode] CHECK  ((len([ZipCode])=(6)))
GO
ALTER TABLE [dbo].[Clients] CHECK CONSTRAINT [ZipCode]
GO
ALTER TABLE [dbo].[ExamDetails]  WITH CHECK ADD  CONSTRAINT [Grade] CHECK  (([Grade]=(5.0) OR [Grade]=(4.5) OR [Grade]=(4.0) OR [Grade]=(3.5) OR [Grade]=(3.0) OR [Grade]=(2.0)))
GO
ALTER TABLE [dbo].[ExamDetails] CHECK CONSTRAINT [Grade]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [ClassSize] CHECK  (([ClassSize]>=(0)))
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [ClassSize]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [Language] CHECK  (([Language] IS NULL OR len([Language])=(2)))
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [Language]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [ModuleEndDate] CHECK  (([ModuleEndDate]>=[ModuleBeginDate]))
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [ModuleEndDate]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [ModulePrice] CHECK  (([ModulePrice]>=(0)))
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [ModulePrice]
GO
ALTER TABLE [dbo].[Modules]  WITH CHECK ADD  CONSTRAINT [ModuleType] CHECK  (([ModuleType]=(1) OR [ModuleType]=(0)))
GO
ALTER TABLE [dbo].[Modules] CHECK CONSTRAINT [ModuleType]
GO
ALTER TABLE [dbo].[PaymentDetails]  WITH CHECK ADD  CONSTRAINT [Amount] CHECK  (([Amount]>(0)))
GO
ALTER TABLE [dbo].[PaymentDetails] CHECK CONSTRAINT [Amount]
GO
ALTER TABLE [dbo].[PaymentDetails]  WITH CHECK ADD  CONSTRAINT [AmountWaived] CHECK  (([AmountWaived]>(0)))
GO
ALTER TABLE [dbo].[PaymentDetails] CHECK CONSTRAINT [AmountWaived]
GO
ALTER TABLE [dbo].[PaymentDetails]  WITH CHECK ADD  CONSTRAINT [DaysWaived] CHECK  (([DaysWaived]>(0)))
GO
ALTER TABLE [dbo].[PaymentDetails] CHECK CONSTRAINT [DaysWaived]
GO
ALTER TABLE [dbo].[Payments]  WITH CHECK ADD  CONSTRAINT [State] CHECK  (([State]=(2) OR [State]=(1) OR [State]=(0)))
GO
ALTER TABLE [dbo].[Payments] CHECK CONSTRAINT [State]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [AccessDate] CHECK  (([AccessDate] IS NULL OR [ServiceType]=(0) AND [AccessDate]>[EndDate]))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [AccessDate]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [AdvancePrice] CHECK  (([AdvancePrice]>=(0) AND [AdvancePrice]<=[ServicePrice]))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [AdvancePrice]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [EndDate] CHECK  (([EndDate]>=[BeginDate]))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [EndDate]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [PassPercent] CHECK  (([PassPercent]>=(0) AND [PassPercent]<=(100)))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [PassPercent]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [ServicePrice] CHECK  (([ServicePrice]>(0)))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [ServicePrice]
GO
ALTER TABLE [dbo].[Services]  WITH CHECK ADD  CONSTRAINT [ServiceType] CHECK  (([ServiceType]=(2) OR [ServiceType]=(1) OR [ServiceType]=(0)))
GO
ALTER TABLE [dbo].[Services] CHECK CONSTRAINT [ServiceType]
GO
ALTER TABLE [dbo].[Subjects]  WITH CHECK ADD  CONSTRAINT [ECTS] CHECK  (([ECTS]>=(0) AND [ECTS]<=(20)))
GO
ALTER TABLE [dbo].[Subjects] CHECK CONSTRAINT [ECTS]
GO
ALTER TABLE [dbo].[Workers]  WITH CHECK ADD  CONSTRAINT [Role] CHECK  (([Role]=(2) OR [Role]=(1) OR [Role]=(0)))
GO
ALTER TABLE [dbo].[Workers] CHECK CONSTRAINT [Role]
GO
ALTER TABLE [dbo].[WorkersLanguages]  WITH CHECK ADD  CONSTRAINT [WorkerLanguage] CHECK  ((len([WorkerLanguage])=(2)))
GO
ALTER TABLE [dbo].[WorkersLanguages] CHECK CONSTRAINT [WorkerLanguage]
GO
/****** Object:  StoredProcedure [dbo].[AddClient]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddClient]
    @Name VARCHAR(50),
    @Surname VARCHAR(50),
    @Street VARCHAR(50) = NULL,
    @HomeNumber VARCHAR(50),
    @City VARCHAR(50),
    @Country VARCHAR(50),
    @ZipCode VARCHAR(50),
    @Email VARCHAR(50),
    @Phone VARCHAR(50)
AS
BEGIN
    INSERT INTO Clients ([Name], Surname, Street, HomeNumber, City, Country, ZipCode, Email, Phone)
    VALUES (@Name, @Surname, @Street, @HomeNumber, @City, @Country, @ZipCode, @Email, @Phone)
END
GO
/****** Object:  StoredProcedure [dbo].[AddLanguageToTranslator]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddLanguageToTranslator]
    @WorkerId int,
    @Language VARCHAR(50)
AS
BEGIN
    INSERT INTO WorkersLanguages 
    VALUES (@WorkerId, @Language)
END
GO
/****** Object:  StoredProcedure [dbo].[AddModule]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddModule]
    @ServiceId int,
    @BeginDate datetime,
    @EndDate datetime,
    @ModuleType tinyint,
    @Class VARCHAR(50),
    @ClassSize tinyint,
    @SubjectId int,
    @LecturerId int,
    @ModulePrice money,
    @TranslatorId int = NULL,
    @Language VARCHAR(50) = NULL
AS
BEGIN
    INSERT INTO Modules (ServiceId, ModuleBeginDate, ModuleEndDate, ModuleType, Class, ClassSize, SubjectId, LecturerId, ModulePrice, TranslatorId, [Language])
    VALUES (@ServiceId, @BeginDate, @EndDate, @ModuleType, @Class, @ClassSize, @SubjectId, @LecturerId, @ModulePrice, @TranslatorId, @Language)
END
GO
/****** Object:  StoredProcedure [dbo].[AddService]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddService]
    @ServiceType tinyint,
    @BeginDate date,
    @EndDate date,
    @ServicePrice money,
    @AdvancePrice money,
    @SyllabusId int = NULL,
    @ExamId int = NULL,
    @CoordinatorId int = NULL,
    @PassPercent tinyint,
    @Title VARCHAR(50),
    @Description VARCHAR(50)
AS
BEGIN
    INSERT INTO Services (ServiceType, BeginDate, EndDate, ServicePrice, AdvancePrice, SyllabusId, ExamId, CoordinatorId, PassPercent, Title, [Description])
    VALUES (@ServiceType, @BeginDate, @EndDate, @ServicePrice, @AdvancePrice, @SyllabusId, @ExamId, @CoordinatorId, @PassPercent, @Title, @Description)
END
GO
/****** Object:  StoredProcedure [dbo].[AddSubject]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddSubject]
    @ECTS tinyint,
    @Description VARCHAR(50)
AS
BEGIN
    INSERT INTO Subjects (ECTS, [Description])
    VALUES (@ECTS, @Description)
END
GO
/****** Object:  StoredProcedure [dbo].[AddWaive]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddWaive]
    @PaymentId int,
    @AmountWaived money = NULL,
    @DaysWaived int = NULL
AS
BEGIN
    UPDATE PaymentDetails
    SET AmountWaived = @AmountWaived, DaysWaived = @DaysWaived
    WHERE PaymentId = @PaymentId
END
GO
/****** Object:  StoredProcedure [dbo].[AddWebinar]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddWebinar]
    @ModuleBeginDate datetime,
    @ModuleEndDate datetime,
    @AccessDate datetime = NULL,
    @ServicePrice money,
    @AdvancePrice money,
    @WebinarSize tinyint,
    @SubjectId int,
    @LecturerId int,
    @TranslatorId int = NULL,
    @Language VARCHAR(50) = NULL,
    @Title VARCHAR(50),
    @Description VARCHAR(50)
AS
BEGIN
    DECLARE @ServiceType tinyint = 0
    DECLARE @ModuleType tinyint = 1
    DECLARE @ServiceBeginDate date = CAST(@ModuleBeginDate AS date)
    DECLARE @ServiceEndDate date = CAST(@ModuleEndDate AS date)
    DECLARE @Output TABLE (ServiceId int)

    INSERT INTO Services (ServiceType, BeginDate, EndDate, ServicePrice, AdvancePrice, Title, [Description])
    OUTPUT INSERTED.ServiceId INTO @Output(ServiceId)
    VALUES (@ServiceType, @ServiceBeginDate, @ServiceEndDate, @ServicePrice, @AdvancePrice, @Title, @Description)

    DECLARE @ServiceId int = (SELECT ServiceId FROM @Output)

    INSERT INTO Modules (ServiceId, ModuleBeginDate, ModuleEndDate, ModuleType, Class, ClassSize, SubjectId, LecturerId, TranslatorId, [Language], ModulePrice)
    VALUES (@ServiceId, @ModuleBeginDate, @ModuleEndDate, @ModuleType, 'online', @WebinarSize, @SubjectId, @LecturerId, @TranslatorId, @Language, @ServicePrice)
END
GO
/****** Object:  StoredProcedure [dbo].[AddWorker]    Script Date: 22/01/2024 12:42:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddWorker]
    @Name VARCHAR(50),
    @Surname VARCHAR(50),
    @Role tinyint
AS
BEGIN
    INSERT INTO Workers ([Name], Surname, [Role])
    VALUES (@Name, @Surname, @Role)
END
GO
USE [master]
GO
ALTER DATABASE [u_stylski] SET  READ_WRITE 
GO
