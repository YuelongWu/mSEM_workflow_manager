function process_one_batch_timer_stopfcn(vTimer, ~)
    try
        Njob = length(getfield(vTimer.UserData,'processed_queue'));
        disp(['Stopped. Processed ',num2str(Njob),' sections.'])
    catch
    end
    
    try diary off; catch;end
    try delete(vTimer); catch;end
end
        