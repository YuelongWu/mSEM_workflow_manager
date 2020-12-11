function send_email_alert(alert_title, alert_msg, recipients)
    if isempty(recipients)
        return;
    end
    % props = java.lang.System.getProperties; props.setProperty('mail.smtp.auth','true'); 
    % props.setProperty( 'mail.smtp.starttls.enable', 'true');
    % setpref('Internet','SMTP_Server','****');
    % setpref('Internet','SMTP_Username','****'); 
    % setpref('Internet','SMTP_Password','****');
    % if ~iscell(recipients)
    %     sendmail(recipients,alert_title,alert_msg);
    % else
    %     % for k = 1:length(recipients)
    %         try
    %             sendmail(recipients,alert_title,alert_msg);
    %         catch
    %             try disp(['Failed to send emails to ', recipients{k}]);catch;end
    %         end
    %     % end
    % end
end