function [recipients,rgroups] = read_email_recipients(txtfile)
    recipients = {};
    rgroups = [];
    crtgroup = 1; % 1: operator; 2: CC list; 3: developer
    fid = fopen(txtfile, 'r');
    k = 1;
    while ~feof(fid)
        recipient = fgetl(fid);
        if contains(recipient, '@')
            recipients{k} = recipient;
            rgroups(k) = crtgroup;
            k = k+1;
        elseif contains(recipient, 'operator:')
            crtgroup = 1;
        elseif contains(recipient, 'CC:')
            crtgroup = 2;
        elseif contains(recipient, 'developer:')
            crtgroup = 3;
        end
    end
    fclose(fid);
end