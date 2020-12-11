function [ovv_info, IMQA_options] = utils_constrain_IMQA_options(res_sec_dir, handles)
    if nargin < 2
        handles = [];
    end

    IMQA_options = [false, false, false, false];
    ovv_info = [];
    wrnmsg = {};

    try
        [res_batch_dir, sec_name] = fileparts(res_sec_dir);

        % allow displaying overview images
        if exist([res_batch_dir, filesep, 'overview_imgs', filesep, sec_name,'.png'],'file')
            IMQA_options(3) = true;
            if ~isempty(handles)
                set(handles.checkbox_overview,'Enable','on');
            end
        else
            IMQA_options(3) = false;
            if ~isempty(handles)
                set(handles.checkbox_overview,'Enable','off');
                wrnmsg = [wrnmsg;{'overview images missing.'}];
            end
        end

        % load processed results
        load([res_sec_dir, filesep, 'ovv_info.mat'],'ovv_info');

        % output warning messages if any infomation is missing
        if ~isempty(handles)
            if ovv_info.regionMetadataStatus == 1
                wrnmsg = [wrnmsg;{'region_metadata.csv corrupted.'}];
            elseif ovv_info.regionMetadataStatus == 2
                wrnmsg = [wrnmsg;{'region_metadata.csv missing.'}];
            elseif ovv_info.regionMetadataStatus == 99
                wrnmsg = [wrnmsg;{'unexpected error happened when parsing region_metadata.csv.'}];
            end
            if ovv_info.focusMapStatus == 1
                wrnmsg = [wrnmsg;{'FocusMap.txt corrupted.'}];
            elseif ovv_info.focusMapStatus == 2
                wrnmsg = [wrnmsg;{'FocusMap.txt missing.'}];
            elseif ovv_info.focusMapStatus == 99
                wrnmsg = [wrnmsg;{'unexpected error happened when parsing FocusMap.txt.'}];
            end
            if ~isempty(wrnmsg)
                warndlg(wrnmsg,'Warning')
            end
        end
        % allow displaying mfov #
        if ovv_info.ovv_coord_ready
            IMQA_options(1) = true;
            if ~isempty(handles)
                set(handles.checkbox_mfov,'Enable','on');
            end
            % allow display IMQA
            if ovv_info.IMQA_coord_ready
                IMQA_options(4) = true;
                if ~isempty(handles)
                    set(handles.checkbox_sfov,'Enable','on');
                end
            else
                IMQA_options(4) = false;
                if ~isempty(handles)
                    set(handles.checkbox_sfov,'Enable','off');
                end
            end
        else
            IMQA_options(1) = false;
            IMQA_options(4) = false;
            if ~isempty(handles)
                set(handles.checkbox_mfov,'Enable','off');
                % not allow display IMQA
                set(handles.checkbox_sfov,'Enable','off');
            end
        end

        % allow display FSP
        if ovv_info.focusMapStatus < 2 && any(all(~isnan(ovv_info.stageCoord')))
            IMQA_options(2) = true;
            if ~isempty(handles)
                set(handles.checkbox_fsp,'Enable','on');
            end
        else
            IMQA_options(2) = false;
            if ~isempty(handles)
                set(handles.checkbox_fsp,'Enable','off');
            end
        end


    catch ME
        if ~isempty(handles)
            errordlg(ME.message, 'Unexpected error.');        
            set(handles.checkbox_mfov,'Enable','off');
            set(handles.checkbox_fsp,'Enable','off');
            set(handles.checkbox_overview,'Enable','off');
            set(handles.checkbox_sfov,'Enable','off');
        end
    end
end