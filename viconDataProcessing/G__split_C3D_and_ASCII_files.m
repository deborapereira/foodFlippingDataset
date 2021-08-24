%% GLOBAL VARIABLE:

EXTRA_TIME = 0.5; % 0.5 seconds before and after the start/end of each movement to save with the movement data

%% split trials by movements

% add path of folders and subfolders where vicon nexus classes are:
addpath(genpath('C:\Program Files (x86)\Vicon\Nexus2.7\SDK\Matlab\'))

% define pipeline path:
pipeline_path = ['C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\'...
    'Pipelines\save_c3d_and_ascii.Pipeline'];

% load the struct storing the frame numbers where to cut the C3D files:
load('D___4_frames_where_to_split_vicon_data.mat', 'init_frame_vicon', 'fin_frame_vicon');

% load the struct storing the length of each trial with vicon:
load('G___viconTrials_length.mat','viconTrials_length');

% load the struct storing the utensil name for each trial:
load('D___2_utensil_struct.mat');

% create instance of vicon nexus:
vicon = ViconNexus();

%%

for s=1:9 % for each subject:
    
    subject = ['S' num2str(s)];
    trials = fieldnames(init_frame_vicon.(subject));
    
    for t=1:length(trials) % for each trial:
        
        % path to the C3D of the current trial:
        path_now = ['F:\C3D__files\' subject '\'];
        
        % open C3D file in Nexus:
        vicon.OpenTrial([path_now trials{t}],30);
        disp(trials{t})
        
        % load MAT file with the markers recovered trajectories and utensils' points of interest:
        dataMAT = load([path_now trials{t} '.mat']);
        
        % create tmp variables to facilitate writing code:
        tmp_init = init_frame_vicon.(subject).(trials{t});
        tmp_fin = fin_frame_vicon.(subject).(trials{t});
        
        % create helper variables to limit the "one second after/before the button"
        % within the size of the signals and without including the next/previous
        % pulses of the button ON:
        last_frame_of_previous_pulse = 1;
        first_frame_of_next_pulse = tmp_init(2)-1;
        
        for d=1:length(tmp_init) % for each movement
            disp(['move ' num2str(d)])
            
            % get the pipeline:
            pipeline = xml2struct(pipeline_path);
            
            % define the start and end of the signals where to split,
            % which is "one second before" and "one second after" the button ON
            initF = max([tmp_init(d)-EXTRA_TIME*100, 1, last_frame_of_previous_pulse]); % -100 frames = one second before
            finF = min([tmp_fin(d)+EXTRA_TIME*100, viconTrials_length.(subject).(trials{t}), first_frame_of_next_pulse]); % +100 frames = one second after
            
            
            % change the pipeline for another file or movement:
            splitFileName = [path_now 'split\' subject '_' utensil.(trials{t}) '_' trials{t} '_m' num2str(d)];
            startFrame = num2str(initF);
            endFrame = num2str(finF);
            
            % 1) change the "Export C3D" operation
            pipeline.Pipeline.Entry{1}.ParamList.Param{1}.Attributes.value = splitFileName;            
            pipeline.Pipeline.Entry{1}.ParamList.Param{2}.Attributes.value = startFrame;            
            pipeline.Pipeline.Entry{1}.ParamList.Param{3}.Attributes.value = endFrame;
            
            % 2) change the "Export ASCII" operation:
            pipeline.Pipeline.Entry{2}.ParamList.Param{1}.Attributes.value = splitFileName;
            pipeline.Pipeline.Entry{2}.ParamList.Param{3}.Attributes.value = startFrame;
            pipeline.Pipeline.Entry{2}.ParamList.Param{4}.Attributes.value = endFrame;
            % NOTE:
            % pipeline.Pipeline.Entry{2}.ParamList.Param{11}.Attributes --> Devices for export
            % pipeline.Pipeline.Entry{2}.ParamList.Param{29}.Attributes --> Trajectories components
            
            
            % save new pipeline:
            struct2xml(pipeline,pipeline_path);
            
            % remove the extension ".xml" added by the function struct2xml:
            oldFilename = ['C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\'...
                'Pipelines\save_c3d_and_ascii.Pipeline.xml'];
            newFilename = pipeline_path;
            delete(newFilename);
            java.io.File(oldFilename).renameTo(java.io.File(newFilename));
            
            % delete unlabeled trajectories before exporting data:
%             vicon.RunPipeline('delete_unlabeled_traj','Shared',45);
                        
            % run the pipeline to export the splitted data:
            vicon.RunPipeline('save_c3d_and_ascii','Shared',45);
            
            
            % split also the MAT file: 
            button = dataMAT.button(initF:finF);
            markers_names = fieldnames(dataMAT.recovered_trajectories);
            for mk=1:length(markers_names)
                recovered_trajectories.(markers_names{mk}) = dataMAT.recovered_trajectories.(markers_names{mk})(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);            
            end
            
            if strcmp(utensil.(trials{t}),'spatula')
                blade_corners.Lclose = dataMAT.blade_corners.Lclose(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                blade_corners.Lfar = dataMAT.blade_corners.Lfar(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                blade_corners.Rclose = dataMAT.blade_corners.Rclose(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                blade_corners.Rfar = dataMAT.blade_corners.Rfar(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                
                save([splitFileName '.mat'], 'button', 'blade_corners', 'recovered_trajectories')
                
            else % tweezers
                tips_position.arm_loadcell = dataMAT.tips_position.arm_loadcell(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                tips_position.arm_no_loadcell = dataMAT.tips_position.arm_no_loadcell(initF-(dataMAT.start_frame-1):finF-(dataMAT.start_frame-1),:);
                
                save([splitFileName '.mat'], 'button', 'tips_position', 'recovered_trajectories')
                
            end
            clearvars button blade_corners recovered_trajectories tips_position
            
            % update the helper variables:
            last_frame_of_previous_pulse = tmp_fin(d)+1; % one frame after the last frame of the current movement
            if d < length(tmp_init)-1
                first_frame_of_next_pulse = tmp_init(d+2)-1; % one frame before the first frame the following movement
            elseif d == length(tmp_init)-1 % the next iteration will be the last movement
                first_frame_of_next_pulse = viconTrials_length.(subject).(trials{t}); % last frame of the signal
            end
        end
        vicon.SaveTrial(30);
        clearvars dataMAT 
    end
end



