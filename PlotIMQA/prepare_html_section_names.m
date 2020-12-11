function sectionstrs = prepare_html_section_names(section_names, ifvalidated, ifready)
    Ns = length(section_names);
    html_head = cell(Ns,1);
    try
        outcell = split(section_names,'_');
        if length(section_names) == 1
            section_names = outcell(end);
        else
            section_names = outcell(:,end);
        end
    end
    html_head(round(ifvalidated) == 1) = {'<HTML><FONT COLOR="Black" SIZE="4" FACE="ARIAL">'};
    html_head(round(ifvalidated) == -1) = {'<HTML><FONT COLOR="Fuchsia" SIZE="4" FACE="ARIAL">'};
    html_head(round(ifvalidated) == 0) = {'<HTML><FONT COLOR="Orange" SIZE="4" FACE="ARIAL">'};
    html_head(abs(ifvalidated-round(ifvalidated)) > 0.05) = {'<HTML><font SIZE="4" FACE="ARIAL" style="color:blue;text-decoration:line-through">'}; % discarded
    html_head(~ifready) = {'<HTML><FONT COLOR="silver" SIZE="4" FACE="ARIAL">'};
    html_tail = '</HTML>';
    sectionstrs = strcat(html_head,section_names,html_tail);
end
    