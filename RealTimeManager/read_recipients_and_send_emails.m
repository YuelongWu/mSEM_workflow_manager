function read_recipients_and_send_emails(alert_title, alert_msg, alert_groups)
if nargin < 3
    alert_groups = [1,2,3];
end
try
    [recipients,rgroups] = read_email_recipients(['.', filesep, 'alert_recipients.txt']);
catch
    disp('Failed to read the alert recipients..')
    return
end
try
    ridx = false(size(recipients));
    for k = 1:length(alert_groups)
        ridx = ridx | (rgroups == alert_groups(k));
    end
    % send_email_alert(alert_title, [alert_msg,10,10,'This is an automatically generated email – please do not reply to it.'], recipients)
    send_email_alert(alert_title, alert_msg, recipients(ridx))
    disp(['Notification sent to ', num2str(sum(ridx)),' people.'])
catch
    disp('Failed to send email alert..')
end
end