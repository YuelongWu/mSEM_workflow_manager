function [status, explog_info] = parse_experiment_log_file(experiment_log_dir, waitfile ,verbose)
    if nargin < 3
        verbose = true;
    end
    status = struct;
    status.errRaised = false;
    status.AcqusitionFinished = false;
    explog_info = {};
    try
        fid = fopen(experiment_log_dir,'r');
        if fid == -1
            if waitfile
                pause(10)  % wait 10 second and try again
            end
            fid = fopen(experiment_log_dir,'r');
            if fid == -1
                status.errRaised = true;
                if verbose
                    fprintf(2,['Cannot find the experiment log file: ',strrep(experiment_log_dir,'\','\\'),...
                        '. Discard the operation...\n'])
                end
                return;
            end
        end
        log_content = fread(fid,'*char');
        fclose(fid);
        if contains(log_content', 'Number of Support Points')    % software version may 2019
            scanned_cell  = utils_textscan(log_content, '%*s%s%*s%s%*s%f%*s%f%*s%f%*s%f',{':',';'});
            op_name = scanned_cell{1};
            op_duration = scanned_cell{2};
            op_mfovnum = scanned_cell{3};
            op_fsp = scanned_cell{4};
            op_af = scanned_cell{5};
            op_as = scanned_cell{6};
            if any(strcmp(op_name,'stop experiment'))
                status.AcqusitionFinished = true;
            end
            section_name_tokens = regexp(scanned_cell{1},'stop region "(.+)"','tokens');
            tmpidx = ~cellfun(@isempty,section_name_tokens);
            tmp = vertcat(section_name_tokens{:});
            sectionNameList = vertcat(tmp{:});
            tmp = utils_textscan(op_duration(tmpidx),'%f%*s','[');
            acq_duration = tmp{1};
            mfov_num = op_mfovnum(tmpidx);
            fsp_num = op_fsp(tmpidx);
            success_fsp_num = min(op_af(tmpidx),op_as(tmpidx));
        else
            scanned_cell  = utils_textscan(log_content, '%*s%s%*s%s%*s%f%*s%s',{':',';'});
            op_name = scanned_cell{1};
            op_duration = scanned_cell{2};
            op_mfovnum = scanned_cell{3};
            op_afas = scanned_cell{4};
            if any(strcmp(op_name,'stop experiment'))
                status.AcqusitionFinished = true;
            end
            section_name_tokens = regexp(scanned_cell{1},'stop region "(.+)"','tokens');
            tmpidx = ~cellfun(@isempty,section_name_tokens);
            tmp = vertcat(section_name_tokens{:});
            sectionNameList = vertcat(tmp{:});
            tmp = utils_textscan(op_duration(tmpidx),'%f%*s','[');
            acq_duration = tmp{1};
            mfov_num = op_mfovnum(tmpidx);
            afas_cell = utils_textscan(op_afas(tmpidx),'%f%f','/');
            fsp_num = afas_cell{2};
            success_fsp_num = afas_cell{1};
        end
        legit_entries = (~isnan(fsp_num)) & (~isnan(mfov_num)) & ...
             (~isnan(acq_duration));
        explog_info = cell(length(sectionNameList),1);
        section_info = struct;
        for k = 1:length(sectionNameList)
            section_info.SectionName = sectionNameList{k};
            section_info.duration = acq_duration(k);
            section_info.mfov_num = mfov_num(k);
            section_info.fsp_num = fsp_num(k);
            section_info.success_fsp_num = success_fsp_num(k);
            section_info.legit_entry = legit_entries(k);
            explog_info{k} = section_info;
        end
    catch ExpME
        status.errRaised = true;
        if verbose
             fprintf(2,['Unexpected error happened when parsing the experiment log file: ',strrep(experiment_log_dir,'\','\\'),'.\n'])
             fprintf(2,['\tMATLAB error message: ', strrep(ExpME.message,'\','\\'),'\n'])
             fprintf(2,'\tDiscard the operation...\n')
        end
        try
            fclose(fid);
        catch
        end
    end
end