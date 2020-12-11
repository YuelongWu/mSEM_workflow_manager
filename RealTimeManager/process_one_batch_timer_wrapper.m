function vTimer = process_one_batch_timer_wrapper(batch_dir,sys_result_dir,result_dir,user_options)
    vTimer = timer;
    vTimer.BusyMode = 'drop';
    vTimer.ExecutionMode = 'fixedSpacing';
    vTimer.Period = 30;
    vTimer.TasksToExecute = inf;
    vTimer.TimerFcn = {@process_one_batch_timer_callback,batch_dir,sys_result_dir,result_dir,user_options};
    vTimer.StopFcn = @process_one_batch_timer_stopfcn;
    tUserData = struct;
    tUserData.processed_queue = {};
    tUserData.waitflag = true;
    tUserData.idleTime = 0;
    tUserData.AFASCount = 0;
    tUserData.general_info = struct;
    vTimer.UserData = tUserData;
    vTimer.StartDelay = 0.5;
    start(vTimer)
end
