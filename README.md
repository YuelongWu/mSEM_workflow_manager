MultiSEM Workflow Manager
-------------------------

MultiSEM Workflow Manager is a third-party software that provides several important workflow management functionalities for Zeiss MultiSEM 505 microscope. It was written and tested with MATLAB R2017b, but a newer version of MATLAB before GUIDE deprecation should also work.

# Quick Start

To start using the workflow manager, simply run *msemRealTimeRetakeManager.m*, select the experiment folder generated by the MutiSEM microscope (folder name ended with time-stamp), and a target folder to hold temporary results. *msemRealTimeRetakeManager.m* continuously probes *experiment_log.txt* in the experiment folder to determine whether a new section has been imaged, upon which carries out a collection of data validation tests (including file inventory, overlap test etc.), and saves the validation results to the temporary result folder.

In addition to the real-time mode, you can also run *msemPostProcessingRetakeManager.m*, which can work at the wafer folder level (one level up from the experiment folder).

# Email Alert

The workflow manager can be configured to send out email alert whenever an unexpected error or workflow interruption occurs. To set up the email alert:

- Open *RealTimeManager/send_email_alert.m*, and configure the email server that sends out email by modifying all the *setpref* lines.

- Add the email addresses of the email alert recipients to *alert_recipients.txt*. One line for each recipients

- When running *msemRealTimeRetakeManager.m*, select *send email notification* when prompted.

# Visualize Image Quality Score

To visualize image quality score, run *msemQualityMapViewer.m* and select the temporary result folder. You can click on the color-coded thumnail images in the pop-up window to open the full resolution EM images at the location clicked. you can also select a different section or adjust the apperence of the colormap by changing the options in the control-pannel. In the end, you can flag the section as to "keep" or to "retake" by clicking the radio buttons at the lower-right corner of the control pannel and leave the reason of retake for future references. The selections and comments will be included in the final html report.

# Tracking ROI

The workflow manager includes a light-weight alignment module that roughly aligns the images using affine transform to detect out-of-target sections. To do that, run *msemAlignOverviewStack.m*, select the reference image in any of the *some-experiment-folder/overview_imgs* folder and wait the alignment program to finish. The algined stack is saved to *temporary-result-folders/aligned_overviews*.

# Generating HTML Results

Run *msemGenerateHtmlReport.m* to genrate a tablized summary of the workflow manager results for the datasets.