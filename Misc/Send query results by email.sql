-- Send query results by email
   exec msdb.dbo.sp_send_dbmail
      @profile_name = 'MyProfile', --Put here the Database Mail Profile to be used
      @recipients = @Recipients, --Variable to hold the recipients
      @copy_recipients = @Recipients_cc,
      @blind_copy_recipients = @Recipients_bc,
      @body = @body_txt,
      @subject = @usbject,
      @query = 'select * from ##TempTable', --TempTable is previously populated with the select statement results
      @query_result_width = 350,
      @attach_query_result_as_file = 1,
      @query_attachment_filename = 'Filename.csv',
      @query_result_header = 0
  