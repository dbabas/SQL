create procedure [dbo].[sp_send_merchant_email] 
as


Begin

declare @recordCount int

select @recordCount = isnull(count(*), 0)
from merchand_history 
where stock_code = 'zzz007' and create_timestamp >= getdate() 
order by create_timestamp desc



IF (@recordCount > 0)
begin



EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'YourProfile',
    @recipients = 'recipients@yourcompany.com',
    @query = 'select * from merchand_history 
                where stock_code = ''zzz007'' and create_timestamp >= getdate() 
                order by create_timestamp desc' ,
      @subject = 'Merchant Email ',
       @Body = 'Email Merchant..... ' ,
    @attach_query_result_as_file = 1 ;

End
else
begin

      EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'YourProfile',
       @recipients = 'recipients@yourcompany.com', 
            @BODY = 'No data returned ', 
            @subject = 'Merchant Email'

End
End;