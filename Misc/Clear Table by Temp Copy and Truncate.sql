USE [National Trust Live]
GO

SET NOCOUNT ON

select count(*) from [National Trust$Auto Message Entry]


Declare @DateFilter datetime
Set @DateFilter = '2019-02-28 23:59:59'

select count(*) from [National Trust$Auto Message Entry]
where [Received DateTime] > @DateFilter


select * into [National Trust$TNP Temp Auto Message Entry]
	from [National Trust$Auto Message Entry] 
where [Received DateTime] > @DateFilter

truncate table [National Trust$Auto Message Entry] 

INSERT INTO [dbo].[National Trust$Auto Message Entry]
           ([GUID No_]
           ,[Message Type Code]
           ,[Attachment Path]
           ,[Immediate Action]
           ,[Errored]
           ,[Completed]
           ,[Received DateTime]
           ,[SenderEmail]
           ,[Error Reason]
           ,[MailItem BLOB]
           ,[SenderName]
           ,[Contact No_]
           ,[Interaction Entry No_]
           ,[E-Mail Entry No_])

	SELECT [GUID No_]
		  ,[Message Type Code]
		  ,[Attachment Path]
		  ,[Immediate Action]
		  ,[Errored]
		  ,[Completed]
		  ,[Received DateTime]
		  ,[SenderEmail]
		  ,[Error Reason]
		  ,[MailItem BLOB]
		  ,[SenderName]
		  ,[Contact No_]
		  ,[Interaction Entry No_]
		  ,[E-Mail Entry No_]
	  FROM [dbo].[National Trust$TNP Temp Auto Message Entry]

GO


