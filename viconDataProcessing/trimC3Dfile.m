function [start_frame, folder] = trimC3Dfile(subject, folder, trial, vicon, length_trial)

% ----------------- Nexus setup -------------------------------------------

% define pipeline path:
pipeline_path = ['C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\'...
    'Pipelines\save_c3d.Pipeline'];

% -------------------------------------------------------------------------



if subject==1 && strcmp(trial,'zuch6') 
    trim = true;
    start_frame = 1340;
    end_Frame = 7975;
elseif subject==2 && strcmp(trial,'zuch8')
    trim = true; 
    start_frame = 950;
    end_Frame = length_trial;
elseif subject==3 && strcmp(trial,'zuch5')
    trim = true;
    start_frame = 1;
    end_Frame = 6265;
elseif subject==3 && strcmp(trial,'hamb2') 
    trim = true;
    start_frame = 900;
    end_Frame = length_trial;
elseif subject==3 && strcmp(trial,'zuch6')
    trim = true;
    start_frame = 1076;
    end_Frame = 7328;
elseif subject==4 && strcmp(trial,'eggp1')
    trim = true;
    start_frame = 1;
    end_Frame = 8830;
elseif subject==5 && strcmp(trial,'eggp2')
    trim = true;
    start_frame = 2790;
    end_Frame = length_trial;
elseif subject==5 && strcmp(trial,'zuch5') 
    trim = true;
    start_frame = 8879;
    end_Frame = 23470;
elseif subject==6 && strcmp(trial,'zuch8')
    trim = true;
    start_frame = 1;
    end_Frame = 11030;
elseif subject==7 && strcmp(trial,'zuch5') 
    trim = true;
    start_frame = 7610;
    end_Frame = length_trial;
elseif subject==7 && strcmp(trial,'zuch6')
    trim = true;
    start_frame = 1550;
    end_Frame = 14300;
elseif subject==7 && strcmp(trial,'zuch7')
    trim = true;
    start_frame = 1;
    end_Frame = 14885;
elseif subject==7 && strcmp(trial,'zuch8')
    trim = true;
    start_frame = 1;
    end_Frame = 14380;
elseif subject==8 && strcmp(trial,'eggp2')
    trim = false;
    start_frame = 1060; 
else
    trim = false;
    start_frame = 1;
end




if trim
    
    vicon.OpenTrial([folder '\' trial],30); % open C3D file in Nexus
    
    folder = [folder '\trimmed']; % new C3D file will be placed in the folder "trimmed" with the same filename as the original C3D
    if ~isfolder(folder)
        mkdir(folder)
    end
    
    % delete unlabeled trajectories before exporting the C3D file:
    vicon.RunPipeline('delete_unlabeled_traj','Shared',45);
    
    pipeline = xml2struct(pipeline_path); % get the nexus pipeline structure to modify it
    
    % modify the pipeline with the file name (in the new folder "trimmed"),
    % the start and end frames where to trim:
    pipeline.Pipeline.Entry.ParamList.Param{1}.Attributes.value = [folder '\' trial];
    pipeline.Pipeline.Entry.ParamList.Param{2}.Attributes.value = start_frame;
    pipeline.Pipeline.Entry.ParamList.Param{3}.Attributes.value = end_Frame;
    struct2xml(pipeline,pipeline_path); % save pipeline structure modified
    oldFilename = ['C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\'...
        'Pipelines\save_c3d.Pipeline.xml'];
    newFilename = pipeline_path;
    delete(newFilename); % delete old pipeline file
    java.io.File(oldFilename).renameTo(java.io.File(newFilename)); % remove the extension ".xml" added by the function struct2xml
    vicon.RunPipeline('save_c3d','Shared',45); % run the pipeline to export the trimmed C3D
    vicon.SaveTrial(30);
    
    
else
    vicon.OpenTrial([folder '\' trial],30); % open C3D file in Nexus only to delete unlabeled trajectories
    vicon.RunPipeline('delete_unlabeled_traj','Shared',45); % delete unlabeled trajectories before saving the C3D file
    vicon.SaveTrial(30);
end



end

















