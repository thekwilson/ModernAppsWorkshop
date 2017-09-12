﻿/*
	Target database:	PartsUnlimitedWebsite (configurable)
	Target instance:	(any)
	Generated date:		9/12/2017 5:37:00 PM
	Generated on:		KARLRISSSP4
	Package version:	(undefined)
	Migration version:	(n/a)
	Baseline version:	(n/a)
	ReadyRoll version:	1.14.14.4876
	Migrations pending:	(variable)

	IMPORTANT! "SQLCMD Mode" must be activated prior to execution (under the Query menu in SSMS).

	BEFORE EXECUTING THIS SCRIPT, WE STRONGLY RECOMMEND YOU TAKE A BACKUP OF YOUR DATABASE.

	This SQLCMD script is designed to be executed through MSBuild (via the .sqlproj Deploy target) however 
	it can also be run manually using SQL Management Studio. 

	It was generated by the ReadyRoll build task and contains logic to deploy the database, ensuring that 
	each of the incremental migrations is executed a single time only in alphabetical (filename) 
	order. If any errors occur within those scripts, the deployment will be aborted and the transaction
	rolled-back.

	NOTE: Automatic transaction management is provided for incremental migrations, so you don't need to
		  add any special BEGIN TRAN/COMMIT/ROLLBACK logic in those script files. 
		  However if you require transaction handling in your Pre/Post-Deployment scripts, you will
		  need to add this logic to the source .sql files yourself.
*/

----====================================================================================================================
---- SQLCMD Variables
---- This script is designed to be called by SQLCMD.EXE with variables specified on the command line.
---- However you can also run it in SQL Management Studio by uncommenting this section (CTRL+K, CTRL+U).
--:setvar DatabaseName "PartsUnlimitedWebsite"
--:setvar ReleaseVersion ""
--:setvar ForceDeployWithoutBaseline "False"
--:setvar DeployPath ""
--:setvar DefaultFilePrefix "PartsUnlimitedWebsite"
--:setvar DefaultDataPath ""
--:setvar DefaultLogPath ""
--:setvar DefaultBackupPath ""
----====================================================================================================================

:on error exit -- Instructs SQLCMD to abort execution as soon as an erroneous batch is encountered

:setvar PackageVersion "(undefined)"

GO
:setvar IsSqlCmdEnabled "True"
GO

IF N'$(DatabaseName)' = N'$' + N'(DatabaseName)' OR
   N'$(ReleaseVersion)' = N'$' + N'(ReleaseVersion)' OR
   N'$(ForceDeployWithoutBaseline)' = N'$' + N'(ForceDeployWithoutBaseline)'
      RAISERROR('(This will not throw). Please make sure that all SQLCMD variables are defined before running this script.', 0, 0);
GO

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON; -- Abort the current batch immediately if a statement raises a run-time error and rollback any open transaction(s)

IF N'$(IsSqlCmdEnabled)' <> N'True' -- Is SQLCMD mode not enabled within the execution context (eg. SSMS)
	BEGIN
		IF IS_SRVROLEMEMBER(N'sysadmin') = 1
			BEGIN -- User is sysadmin; abort execution by disconnect the script from the database server
				RAISERROR(N'This script must be run in SQLCMD Mode (under the Query menu in SSMS). Aborting connection to suppress subsequent errors.', 20, 127, N'UNKNOWN') WITH LOG;
			END
		ELSE
			BEGIN -- User is not sysadmin; abort execution by switching off statement execution (script will continue to the end without performing any actual deployment work)
				RAISERROR(N'This script must be run in SQLCMD Mode (under the Query menu in SSMS). Script execution has been halted.', 16, 127, N'UNKNOWN') WITH NOWAIT;
			END
	END
GO
IF @@ERROR != 0
	BEGIN
		SET NOEXEC ON; -- SQLCMD is NOT enabled so prevent any further statements from executing
	END
GO
-- Beyond this point, no further explicit error handling is required because it can be assumed that SQLCMD mode is enabled

IF SERVERPROPERTY('EngineEdition') = 5 AND DB_NAME() != N'$(DatabaseName)'
  RAISERROR(N'Azure SQL Database does not support switching between databases. Connect to [$(DatabaseName)] and then re-run the script.', 16, 127);








------------------------------------------------------------------------------------------------------------------------
------------------------------------------       PRE-DEPLOYMENT SCRIPTS       ------------------------------------------
------------------------------------------------------------------------------------------------------------------------

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;

PRINT '----- executing pre-deployment script "Pre-Deployment\01_Create_Database.sql" -----';
GO

------------------------- BEGIN PRE-DEPLOYMENT SCRIPT: "Pre-Deployment\01_Create_Database.sql" ---------------------------
IF (DB_ID(N'$(DatabaseName)') IS NULL)
BEGIN
	PRINT N'Creating $(DatabaseName)...';
END
GO
IF (DB_ID(N'$(DatabaseName)') IS NULL)
BEGIN
	CREATE DATABASE [$(DatabaseName)]; -- MODIFY THIS STATEMENT TO SPECIFY A COLLATION FOR YOUR DATABASE
END

GO
-------------------------- END PRE-DEPLOYMENT SCRIPT: "Pre-Deployment\01_Create_Database.sql" ----------------------------

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;









------------------------------------------------------------------------------------------------------------------------
------------------------------------------       INCREMENTAL MIGRATIONS       ------------------------------------------
------------------------------------------------------------------------------------------------------------------------

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;

SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;

GO
PRINT '# Beginning transaction';

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SET XACT_ABORT ON;

BEGIN TRANSACTION;

GO
IF DB_ID('$(DatabaseName)') IS NULL
  RAISERROR ('The database [$(DatabaseName)] could not be found. Please ensure that there is a Pre-Deployment script within your project that contains a CREATE DATABASE statement (e.g. Pre-Deployment\01_Create_Database.sql).', 16, 127);

GO
IF DB_NAME() != '$(DatabaseName)'
  USE [$(DatabaseName)];

GO
IF (NOT EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[__MigrationLog]') AND [type] = 'U'))
  BEGIN
    IF OBJECT_ID(N'[dbo].[__MigrationLogCurrent]', 'V') IS NOT NULL
      DROP VIEW [dbo].[__MigrationLogCurrent];
    CREATE TABLE [dbo].[__MigrationLog] (
      [migration_id] UNIQUEIDENTIFIER NOT NULL,
      [script_checksum] NVARCHAR (64) NOT NULL,
      [script_filename] NVARCHAR (255) NOT NULL,
      [complete_dt] DATETIME2 NOT NULL,
      [applied_by] NVARCHAR (100) NOT NULL,
      [deployed] TINYINT CONSTRAINT [DF___MigrationLog_deployed] DEFAULT (1) NOT NULL,
      [version] VARCHAR (255) NULL,
      [package_version] VARCHAR (255) NULL,
      [release_version] VARCHAR (255) NULL,
      [sequence_no] INT IDENTITY (1, 1) NOT NULL CONSTRAINT [PK___MigrationLog] PRIMARY KEY CLUSTERED ([migration_id], [complete_dt], [script_checksum]));
    CREATE NONCLUSTERED INDEX [IX___MigrationLog_CompleteDt]
      ON [dbo].[__MigrationLog]([complete_dt]);
    CREATE NONCLUSTERED INDEX [IX___MigrationLog_Version]
      ON [dbo].[__MigrationLog]([version]);
    CREATE UNIQUE NONCLUSTERED INDEX [UX___MigrationLog_SequenceNo]
      ON [dbo].[__MigrationLog]([sequence_no]);
    EXECUTE ('
	CREATE VIEW [dbo].[__MigrationLogCurrent]
			AS
			WITH currentMigration AS
			(
			  SELECT 
				 migration_id, script_checksum, script_filename, complete_dt, applied_by, deployed, ROW_NUMBER() OVER(PARTITION BY migration_id ORDER BY sequence_no DESC) AS RowNumber
			  FROM [dbo].[__MigrationLog]
			)
			SELECT  migration_id, script_checksum, script_filename, complete_dt, applied_by, deployed
			FROM currentMigration
			WHERE RowNumber = 1
	');
    IF OBJECT_ID(N'sp_addextendedproperty', 'P') IS NOT NULL
      BEGIN
        PRINT N'Creating extended properties';
        EXECUTE sp_addextendedproperty N'MS_Description', N'This table is required by ReadyRoll SQL Projects to keep track of which migrations have been executed during deployment. Please do not alter or remove this table from the database.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', NULL, NULL;
        EXECUTE sp_addextendedproperty N'MS_Description', N'The executing user at the time of deployment (populated using the SYSTEM_USER function).', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'applied_by';
        EXECUTE sp_addextendedproperty N'MS_Description', N'The date/time that the migration finished executing. This value is populated using the SYSDATETIME function in SQL Server 2008+ or by using GETDATE in SQL Server 2005.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'complete_dt';
        EXECUTE sp_addextendedproperty N'MS_Description', N'This column contains a number of potential states:

0 - Marked As Deployed: The migration was not executed.
1- Deployed: The migration was executed successfully.
2- Imported: The migration was generated by importing from this DB.

"Marked As Deployed" and "Imported" are similar in that the migration was not executed on this database; it was was only marked as such to prevent it from executing during subsequent deployments.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'deployed';
        EXECUTE sp_addextendedproperty N'MS_Description', N'The unique identifier of a migration script file. This value is stored within the <Migration /> Xml fragment within the header of the file itself.

Note that it is possible for this value to repeat in the [__MigrationLog] table. In the case of programmable object scripts, a record will be inserted with a particular ID each time a change is made to the source file and subsequently deployed.

In the case of a migration, you may see the same [migration_id] repeated, but only in the scenario where the "Mark As Deployed" button/command has been run.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'migration_id';
        EXECUTE sp_addextendedproperty N'MS_Description', N'If you have enabled SQLCMD Packaging in your ReadyRoll project, or if you are using Octopus Deploy, this will be the version number that your database package was stamped with at build-time.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'package_version';
        EXECUTE sp_addextendedproperty N'MS_Description', N'If you are using Octopus Deploy, you can use the value in this column to look-up which release was responsible for deploying this migration.
If deploying via PowerShell, set the $ReleaseVersion variable to populate this column.
If deploying via Visual Studio, this column will always be NULL.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'release_version';
        EXECUTE sp_addextendedproperty N'MS_Description', N'A SHA256 representation of the migration script file at the time of build.  This value is used to determine whether a migration has been changed since it was deployed. In the case of a programmable object script, a different checksum will cause the migration to be redeployed.
Note: if any variables have been specified as part of a deployment, this will not affect the checksum value.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'script_checksum';
        EXECUTE sp_addextendedproperty N'MS_Description', N'The name of the migration script file on disk, at the time of build.
If Semantic Versioning has been enabled, then this value will contain the full relative path from the root of the project folder. If it is not enabled, then it will simply contain the filename itself.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'script_filename';
        EXECUTE sp_addextendedproperty N'MS_Description', N'An auto-seeded numeric identifier that can be used to determine the order in which migrations were deployed.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'sequence_no';
        EXECUTE sp_addextendedproperty N'MS_Description', N'The semantic version that this migration was created under. In ReadyRoll projects, a folder can be given a version number, e.g. 1.0.0, and one or more migration scripts can be stored within that folder to provide logical grouping of related database changes.', 'SCHEMA', N'dbo', 'TABLE', N'__MigrationLog', 'COLUMN', N'version';
        EXECUTE sp_addextendedproperty N'MS_Description', N'This view is required by ReadyRoll SQL Projects to determine whether a migration should be executed during a deployment. The view lists the most recent [__MigrationLog] entry for a given [migration_id], which is needed to determine whether a particular programmable object script needs to be (re)executed: a non-matching checksum on the current [__MigrationLog] entry will trigger the execution of a programmable object script. Please do not alter or remove this table from the database.', N'SCHEMA', N'dbo', N'VIEW', N'__MigrationLogCurrent', NULL, NULL;
      END
  END

IF NOT EXISTS (SELECT col.COLUMN_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tab, INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS col WHERE col.CONSTRAINT_NAME = tab.CONSTRAINT_NAME AND col.TABLE_NAME = tab.TABLE_NAME AND col.TABLE_SCHEMA = tab.TABLE_SCHEMA AND tab.CONSTRAINT_TYPE = 'PRIMARY KEY' AND col.TABLE_SCHEMA = 'dbo' AND col.TABLE_NAME = '__MigrationLog' AND col.COLUMN_NAME = 'complete_dt')
  BEGIN
    RAISERROR (N'The ReadyRoll [dbo].[__MigrationLog] table has an incorrect primary key specification. This may be due to the fact that the <ReadyRollToolsVersion/> element in your .sqlproj file contains the wrong version number for your database. Please check earlier versions of your .sqlproj file to determine what is the appropriate version for your database (possibly 1.7 or 1.3.1).', 16, 127, N'UNKNOWN')
      WITH NOWAIT;
    RETURN;
  END

IF COL_LENGTH(N'[dbo].[__MigrationLog]', N'sequence_no') IS NULL
  BEGIN
    RAISERROR (N'The ReadyRoll [dbo].[__MigrationLog] table is missing the [sequence_no] column. This may be due to the fact that the <ReadyRollToolsVersion/> element in your .sqlproj file contains the wrong version number for your database. Please check earlier versions of your .sqlproj file to determine what is the appropriate version for your database (possibly 1.7 or 1.3.1).', 16, 127, N'UNKNOWN')
      WITH NOWAIT;
    RETURN;
  END

IF (NOT EXISTS (SELECT * FROM sys.objects WHERE [object_id] = OBJECT_ID(N'[dbo].[__MigrationLogCurrent]') AND [type] = 'V'))
  BEGIN
    EXECUTE ('
	CREATE VIEW [dbo].[__MigrationLogCurrent]
			AS
			WITH currentMigration AS
			(
			  SELECT 
				 migration_id, script_checksum, script_filename, complete_dt, applied_by, deployed, ROW_NUMBER() OVER(PARTITION BY migration_id ORDER BY sequence_no DESC) AS RowNumber
			  FROM [dbo].[__MigrationLog]
			)
			SELECT  migration_id, script_checksum, script_filename, complete_dt, applied_by, deployed
			FROM currentMigration
			WHERE RowNumber = 1
	');
  END

GO
DECLARE @baselineRequired AS BIT;

SET @baselineRequired = 0;

IF (EXISTS (SELECT * FROM sys.objects AS o WHERE o.is_ms_shipped = 0 AND NOT o.name LIKE '%__MigrationLog%') AND (SELECT count(*) FROM [dbo].[__MigrationLog]) = 0)
  SET @baselineRequired = 1;

IF @baselineRequired = 1
  IF '$(ForceDeployWithoutBaseline)' != 'True'
    RAISERROR ('A baseline has not been set for this project, however pre-existing objects have been found in this database. Please set a baseline in the Visual Studio Project Settings, or set ForceDeployWithoutBaseline=True to continue deploying without a baseline.', 16, 127);

GO
SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;

SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;

GO
IF DB_NAME() != '$(DatabaseName)'
  USE [$(DatabaseName)];

GO
IF NOT EXISTS (SELECT 1 FROM [$(DatabaseName)].[dbo].[__MigrationLogCurrent] WHERE [migration_id] = CAST ('49007de4-1c01-4d5d-90d9-5656767af1fe' AS UNIQUEIDENTIFIER))
  PRINT '

***** EXECUTING MIGRATION "Migrations\0001_20170912-1438_karlriss.sql", ID: {49007de4-1c01-4d5d-90d9-5656767af1fe} *****';

GO
IF EXISTS (SELECT 1 FROM [$(DatabaseName)].[dbo].[__MigrationLogCurrent] WHERE [migration_id] = CAST ('49007de4-1c01-4d5d-90d9-5656767af1fe' AS UNIQUEIDENTIFIER))
  SET NOEXEC ON;

GO
EXECUTE ('
PRINT N''Creating [dbo].[AspNetUsers]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[AspNetUsers]
(
[Id] [nvarchar] (128) NOT NULL,
[Name] [nvarchar] (max) NULL,
[Email] [nvarchar] (256) NULL,
[EmailConfirmed] [bit] NOT NULL,
[PasswordHash] [nvarchar] (max) NULL,
[SecurityStamp] [nvarchar] (max) NULL,
[PhoneNumber] [nvarchar] (max) NULL,
[PhoneNumberConfirmed] [bit] NOT NULL,
[TwoFactorEnabled] [bit] NOT NULL,
[LockoutEndDateUtc] [datetime] NULL,
[LockoutEnabled] [bit] NOT NULL,
[AccessFailedCount] [int] NOT NULL,
[UserName] [nvarchar] (256) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.AspNetUsers] on [dbo].[AspNetUsers]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUsers] ADD CONSTRAINT [PK_dbo.AspNetUsers] PRIMARY KEY CLUSTERED  ([Id])
');

GO
EXECUTE ('PRINT N''Creating index [UserNameIndex] on [dbo].[AspNetUsers]''
');

GO
EXECUTE ('CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex] ON [dbo].[AspNetUsers] ([UserName])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[AspNetUserClaims]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[AspNetUserClaims]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[UserId] [nvarchar] (128) NOT NULL,
[ClaimType] [nvarchar] (max) NULL,
[ClaimValue] [nvarchar] (max) NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.AspNetUserClaims] on [dbo].[AspNetUserClaims]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserClaims] ADD CONSTRAINT [PK_dbo.AspNetUserClaims] PRIMARY KEY CLUSTERED  ([Id])
');

GO
EXECUTE ('PRINT N''Creating index [IX_UserId] on [dbo].[AspNetUserClaims]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserClaims] ([UserId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[AspNetUserLogins]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[AspNetUserLogins]
(
[LoginProvider] [nvarchar] (128) NOT NULL,
[ProviderKey] [nvarchar] (128) NOT NULL,
[UserId] [nvarchar] (128) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.AspNetUserLogins] on [dbo].[AspNetUserLogins]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserLogins] ADD CONSTRAINT [PK_dbo.AspNetUserLogins] PRIMARY KEY CLUSTERED  ([LoginProvider], [ProviderKey], [UserId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_UserId] on [dbo].[AspNetUserLogins]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserLogins] ([UserId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[AspNetRoles]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[AspNetRoles]
(
[Id] [nvarchar] (128) NOT NULL,
[Name] [nvarchar] (256) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.AspNetRoles] on [dbo].[AspNetRoles]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetRoles] ADD CONSTRAINT [PK_dbo.AspNetRoles] PRIMARY KEY CLUSTERED  ([Id])
');

GO
EXECUTE ('PRINT N''Creating index [RoleNameIndex] on [dbo].[AspNetRoles]''
');

GO
EXECUTE ('CREATE UNIQUE NONCLUSTERED INDEX [RoleNameIndex] ON [dbo].[AspNetRoles] ([Name])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[AspNetUserRoles]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[AspNetUserRoles]
(
[UserId] [nvarchar] (128) NOT NULL,
[RoleId] [nvarchar] (128) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.AspNetUserRoles] on [dbo].[AspNetUserRoles]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserRoles] ADD CONSTRAINT [PK_dbo.AspNetUserRoles] PRIMARY KEY CLUSTERED  ([UserId], [RoleId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_RoleId] on [dbo].[AspNetUserRoles]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_RoleId] ON [dbo].[AspNetUserRoles] ([RoleId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_UserId] on [dbo].[AspNetUserRoles]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_UserId] ON [dbo].[AspNetUserRoles] ([UserId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[Products]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[Products]
(
[ProductId] [int] NOT NULL IDENTITY(1, 1),
[SkuNumber] [nvarchar] (max) NOT NULL,
[CategoryId] [int] NOT NULL,
[RecommendationId] [int] NOT NULL,
[Title] [nvarchar] (160) NOT NULL,
[Price] [decimal] (18, 2) NOT NULL,
[SalePrice] [decimal] (18, 2) NOT NULL,
[ProductArtUrl] [nvarchar] (1024) NULL,
[Description] [nvarchar] (max) NOT NULL,
[Created] [datetime] NOT NULL,
[ProductDetails] [nvarchar] (max) NOT NULL,
[Inventory] [int] NOT NULL,
[LeadTime] [int] NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.Products] on [dbo].[Products]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Products] ADD CONSTRAINT [PK_dbo.Products] PRIMARY KEY CLUSTERED  ([ProductId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_CategoryId] on [dbo].[Products]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_CategoryId] ON [dbo].[Products] ([CategoryId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[CartItems]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[CartItems]
(
[CartItemId] [int] NOT NULL IDENTITY(1, 1),
[CartId] [nvarchar] (max) NOT NULL,
[ProductId] [int] NOT NULL,
[Count] [int] NOT NULL,
[DateCreated] [datetime] NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.CartItems] on [dbo].[CartItems]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[CartItems] ADD CONSTRAINT [PK_dbo.CartItems] PRIMARY KEY CLUSTERED  ([CartItemId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_ProductId] on [dbo].[CartItems]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_ProductId] ON [dbo].[CartItems] ([ProductId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[Orders]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[Orders]
(
[OrderId] [int] NOT NULL IDENTITY(1, 1),
[OrderDate] [datetime] NOT NULL,
[Username] [nvarchar] (max) NOT NULL,
[Name] [nvarchar] (160) NOT NULL,
[Address] [nvarchar] (70) NOT NULL,
[City] [nvarchar] (40) NOT NULL,
[State] [nvarchar] (40) NOT NULL,
[PostalCode] [nvarchar] (10) NOT NULL,
[Country] [nvarchar] (40) NOT NULL,
[Phone] [nvarchar] (24) NOT NULL,
[Email] [nvarchar] (max) NOT NULL,
[Total] [decimal] (18, 2) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.Orders] on [dbo].[Orders]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [PK_dbo.Orders] PRIMARY KEY CLUSTERED  ([OrderId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[OrderDetails]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[OrderDetails]
(
[OrderDetailId] [int] NOT NULL IDENTITY(1, 1),
[OrderId] [int] NOT NULL,
[ProductId] [int] NOT NULL,
[Count] [int] NOT NULL,
[UnitPrice] [decimal] (18, 2) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.OrderDetails] on [dbo].[OrderDetails]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[OrderDetails] ADD CONSTRAINT [PK_dbo.OrderDetails] PRIMARY KEY CLUSTERED  ([OrderDetailId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_OrderId] on [dbo].[OrderDetails]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_OrderId] ON [dbo].[OrderDetails] ([OrderId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_ProductId] on [dbo].[OrderDetails]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_ProductId] ON [dbo].[OrderDetails] ([ProductId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[Categories]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[Categories]
(
[CategoryId] [int] NOT NULL IDENTITY(1, 1),
[Name] [nvarchar] (max) NOT NULL,
[Description] [nvarchar] (max) NULL,
[ImageUrl] [nvarchar] (max) NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.Categories] on [dbo].[Categories]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Categories] ADD CONSTRAINT [PK_dbo.Categories] PRIMARY KEY CLUSTERED  ([CategoryId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[Rainchecks]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[Rainchecks]
(
[RaincheckId] [int] NOT NULL IDENTITY(1, 1),
[Name] [nvarchar] (max) NULL,
[ProductId] [int] NOT NULL,
[Count] [int] NOT NULL,
[SalePrice] [float] NOT NULL,
[StoreId] [int] NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.Rainchecks] on [dbo].[Rainchecks]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Rainchecks] ADD CONSTRAINT [PK_dbo.Rainchecks] PRIMARY KEY CLUSTERED  ([RaincheckId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_ProductId] on [dbo].[Rainchecks]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_ProductId] ON [dbo].[Rainchecks] ([ProductId])
');

GO
EXECUTE ('PRINT N''Creating index [IX_StoreId] on [dbo].[Rainchecks]''
');

GO
EXECUTE ('CREATE NONCLUSTERED INDEX [IX_StoreId] ON [dbo].[Rainchecks] ([StoreId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[Stores]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[Stores]
(
[StoreId] [int] NOT NULL IDENTITY(1, 1),
[Name] [nvarchar] (max) NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.Stores] on [dbo].[Stores]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Stores] ADD CONSTRAINT [PK_dbo.Stores] PRIMARY KEY CLUSTERED  ([StoreId])
');

GO
EXECUTE ('PRINT N''Creating [dbo].[__MigrationHistory]''
');

GO
EXECUTE ('CREATE TABLE [dbo].[__MigrationHistory]
(
[MigrationId] [nvarchar] (150) NOT NULL,
[ContextKey] [nvarchar] (300) NOT NULL,
[Model] [varbinary] (max) NOT NULL,
[ProductVersion] [nvarchar] (32) NOT NULL
)
');

GO
EXECUTE ('PRINT N''Creating primary key [PK_dbo.__MigrationHistory] on [dbo].[__MigrationHistory]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[__MigrationHistory] ADD CONSTRAINT [PK_dbo.__MigrationHistory] PRIMARY KEY CLUSTERED  ([MigrationId], [ContextKey])
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[AspNetUserRoles]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserRoles] ADD CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE CASCADE
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserRoles] ADD CONSTRAINT [FK_dbo.AspNetUserRoles_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[AspNetUserClaims]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserClaims] ADD CONSTRAINT [FK_dbo.AspNetUserClaims_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[AspNetUserLogins]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[AspNetUserLogins] ADD CONSTRAINT [FK_dbo.AspNetUserLogins_dbo.AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[CartItems]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[CartItems] ADD CONSTRAINT [FK_dbo.CartItems_dbo.Products_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[Products]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Products] ADD CONSTRAINT [FK_dbo.Products_dbo.Categories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[OrderDetails]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[OrderDetails] ADD CONSTRAINT [FK_dbo.OrderDetails_dbo.Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([OrderId]) ON DELETE CASCADE
');

GO
EXECUTE ('ALTER TABLE [dbo].[OrderDetails] ADD CONSTRAINT [FK_dbo.OrderDetails_dbo.Products_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]) ON DELETE CASCADE
');

GO
EXECUTE ('PRINT N''Adding foreign keys to [dbo].[Rainchecks]''
');

GO
EXECUTE ('ALTER TABLE [dbo].[Rainchecks] ADD CONSTRAINT [FK_dbo.Rainchecks_dbo.Products_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]) ON DELETE CASCADE
');

GO
EXECUTE ('ALTER TABLE [dbo].[Rainchecks] ADD CONSTRAINT [FK_dbo.Rainchecks_dbo.Stores_StoreId] FOREIGN KEY ([StoreId]) REFERENCES [dbo].[Stores] ([StoreId]) ON DELETE CASCADE
');

GO
SET NOEXEC OFF;

GO
IF N'$(IsSqlCmdEnabled)' <> N'True'
  SET NOEXEC ON;

GO
IF NOT EXISTS (SELECT 1 FROM [$(DatabaseName)].[dbo].[__MigrationLogCurrent] WHERE [migration_id] = CAST ('49007de4-1c01-4d5d-90d9-5656767af1fe' AS UNIQUEIDENTIFIER))
  PRINT '***** FINISHED EXECUTING MIGRATION "Migrations\0001_20170912-1438_karlriss.sql", ID: {49007de4-1c01-4d5d-90d9-5656767af1fe} *****
';

GO
IF NOT EXISTS (SELECT 1 FROM [$(DatabaseName)].[dbo].[__MigrationLogCurrent] WHERE [migration_id] = CAST ('49007de4-1c01-4d5d-90d9-5656767af1fe' AS UNIQUEIDENTIFIER))
  INSERT [$(DatabaseName)].[dbo].[__MigrationLog] ([migration_id], [script_checksum], [script_filename], [complete_dt], [applied_by], [deployed], [version], [package_version], [release_version])
  VALUES                                         (CAST ('49007de4-1c01-4d5d-90d9-5656767af1fe' AS UNIQUEIDENTIFIER), '7DD39A2B09DD2BBC2DF428408D361A547643488C4FAF0F12BBA29363FE2B2C34', '0001_20170912-1438_karlriss.sql', SYSDATETIME(), SYSTEM_USER, 1, NULL, '$(PackageVersion)', CASE '$(ReleaseVersion)' WHEN '' THEN NULL ELSE '$(ReleaseVersion)' END);

GO
PRINT '# Committing transaction';

COMMIT TRANSACTION;

GO







------------------------------------------------------------------------------------------------------------------------
------------------------------------------       POST-DEPLOYMENT SCRIPTS      ------------------------------------------
------------------------------------------------------------------------------------------------------------------------

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;
IF DB_NAME() != '$(DatabaseName)'
    USE [$(DatabaseName)];

PRINT '----- executing post-deployment script "Post-Deployment\01_Finalize_Deployment.sql" -----';
GO

---------------------- BEGIN POST-DEPLOYMENT SCRIPT: "Post-Deployment\01_Finalize_Deployment.sql" ------------------------
/*
Post-Deployment Script Template
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.
 Use SQLCMD syntax to include a file in the post-deployment script.
 Example:      :r .\myfile.sql
 Use SQLCMD syntax to reference a variable in the post-deployment script.
 Example:      :setvar TableName MyTable
               SELECT * FROM [$(TableName)]
--------------------------------------------------------------------------------------
*/

GO
----------------------- END POST-DEPLOYMENT SCRIPT: "Post-Deployment\01_Finalize_Deployment.sql" -------------------------

SET IMPLICIT_TRANSACTIONS, NUMERIC_ROUNDABORT OFF;
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, NOCOUNT, QUOTED_IDENTIFIER ON;
IF DB_NAME() != '$(DatabaseName)'
    USE [$(DatabaseName)];


IF SERVERPROPERTY('EngineEdition') != 5 AND HAS_PERMS_BY_NAME(N'sys.xp_logevent', N'OBJECT', N'EXECUTE') = 1
BEGIN
  DECLARE @databaseName AS nvarchar(2048), @eventMessage AS nvarchar(2048)
  SET @databaseName = REPLACE(REPLACE(DB_NAME(), N'\', N'\\'), N'"', N'\"')
  SET @eventMessage = N'Redgate ReadyRoll: { "deployment": { "description": "ReadyRoll deployed $(ReleaseVersion) to ' + @databaseName + N'", "database": "' + @databaseName + N'" }}'
  EXECUTE sys.xp_logevent 55000, @eventMessage
END
PRINT 'Deployment completed successfully.'
GO




SET NOEXEC OFF; -- Resume statement execution if an error occurred within the script pre-amble
