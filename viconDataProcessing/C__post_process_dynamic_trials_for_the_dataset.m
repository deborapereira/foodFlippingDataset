%% add mocap toolboxes to searched paths
addpath(genpath('MocapRecovery-master'))

%% global vars:
THRESH = 0.9; % max threshold for the variations of inter-markers distance near gaps
EXTRA_TIME = 0.5; % 0.5 seconds before and after the start/end of each movement to save with the movement data


%% load auxiliary data:

% points of interest in the utensils, in the local coordinate systems:
load('A__tweezers_tips_in_local_coordinates.mat','tip_pos_arm_cell','tip_pos_arm_notcell')
load('B__spatula_blade_corners_in_local_coordinates.mat','bladeCloseCorner',...
    'bladeRfarCorner','bladeLfarCorner','bladeLCloseCorner')

% load the vicon button signals that were generated from the FT button signals
% to be saved together with the 3D trajectories of the tweezers tips:
load('D___4_frames_where_to_split_vicon_data.mat','buttonVicon_corrected')

% utensil struct
load('D___2_utensil_struct.mat')


%% post-processing

trials = {'hamb1', 'hamb2', 'hamb3', 'hamb4', 'hamb5', 'hamb6', 'chic1', 'chic2',...
          'zuch1', 'zuch2', 'zuch3', 'zuch4', 'zuch5', 'zuch6', ...
          'zuch7', 'zuch8', 'zuch9', 'eggp1', 'eggp2', 'eggp3'};


% ----------------- Nexus setup -------------------------------------------

% add path of folders and subfolders where vicon nexus classes are:
addpath(genpath('C:\Program Files (x86)\Vicon\Nexus2.7\SDK\Matlab\'))

% create instance of vicon nexus in case a trial needs to be trimmed:
vicon = ViconNexus();

% -------------------------------------------------------------------------



for s=1:9
    for t=1:length(trials)
        clearvars recovered_trajectories markersname marker original...
            tmp_markersName folder recovered blade_corners tips_position...
            button start_frame
        folder = ['F:\C3D__files\S' num2str(s)];
        path_now = [folder '\' trials{t} '.c3d'];
        
        if isfile(path_now)
            disp(path_now)
            
            % TRIM C3D, FIRST, IF NECESSARY -------------------------------------------------
            
            % this was necessary only to remove initial parts of the trial
            % where nothing happens, so we didn't label markers and it
            % would influence the algorithm that recovers missing data
            button = buttonVicon_corrected.(['S' num2str(s)]).(trials{t});
            [start_frame, folder] = trimC3Dfile(s, folder, trials{t}, vicon, length(button));
            path_now = [folder '\' trials{t} '.c3d']; % update path, in case the file was trimmed
            
            
            % LOAD DATA ---------------------------------------------------------------------
            
            original = mcread(path_now);
            markersname.(['S' num2str(s) '_' trials{t}]) = original.markerName;
            
            % correct markers' name in case it has the utensil name as prefix:
            if strcmp(original.markerName{1}(1:2),'sp') 
                for n=1:length(original.markerName) % remove "spatula:" at the beginning of the markers' name
                    markersname.(['S' num2str(s) '_' trials{t}]){n} = markersname.(['S' num2str(s) '_' trials{t}]){n}(9:end);
                end
            elseif strcmp(original.markerName{1}(1:2),'tw')
                for n=1:length(original.markerName) % remove "tweezers:" at the beginning of the markers' name
                    markersname.(['S' num2str(s) '_' trials{t}]){n} = markersname.(['S' num2str(s) '_' trials{t}]){n}(10:end);
                end
            end
            clearvars n
            
                
            %  CLEAN FILTER ARTIFACTS -------------------------------------------------------
            
            % this part can be commented if no filter was applied to the
            % data, as the case of our data
            tmp_markersName = repelem(markersname.(['S' num2str(s) '_' trials{t}]),3);
            
            if strcmp(utensil.(trials{t}),'spatula')
                
                % remove isolated points in the trajectories (i.e. points with NaNs on both sides):
                for m=1:3:length(tmp_markersName)
                    eval(['marker.' tmp_markersName{m} ' = original.data(:,m:m+2);']);
                    notNaN = ~isnan(marker.(tmp_markersName{m})(:,1));
                    idx = [false; (notNaN(2:end-1) - notNaN(1:end-2)) == 1 & (notNaN(2:end-1)-notNaN(3:end)) == 1; false];
                    if ~isempty(find(idx,1))
                        marker.(tmp_markersName{m})(idx,:) = NaN;
                        original.data(:,m:m+2) = marker.(tmp_markersName{m});
                    end
                end
                
                % correct filtering artifacts in gaps extremities:
                for m=1:3:length(tmp_markersName)
                    if ~strcmp(tmp_markersName{m},'logRefp') && ~strcmp(tmp_markersName{m},'logRefy')
                        marker = remArtifacts(marker, tmp_markersName{m}, 0.9);
                        original.data(:,m:m+2) = marker.(tmp_markersName{m});
                    end
                end
                clearvars idx m notNaN
            end 
            
            
            % RECOVER LOST MARKERS ----------------------------------------------------------
            
            %  Tits, M. et al., 2018, PloS one  [ https://github.com/numediart/MocapRecovery ]
            options.method1 = 1; % Local interpolation
            options.method2 = 1; % Local polynomial regression
            options.method3 = 1; % Local GRNN
            options.method4 = 1; % Global weighted linear regression
            options.method5 = 1; % Gloersen et al. 2016
            options.advancedordering = 1;
            options.spaceconstraint = 1;%use or not spaceconstraint
            options.timeconstraint = 1;%use or not timeconstraint
            options.filtering = 1;%use or not timeconstraint
            options.quiet = 1;%avoid console output
            options.presenceMin = 30;%threshold (in % of available frames) under which discard some markers
            
            tic;
            recovered = mcrecovery(original,options);
            toc;
            
            clearvars options
            
            
            % CALCULATE POINTS OF INTEREST --------------------------------------------------
            
            % markers trajectories without gaps:
            for m=1:3:length(tmp_markersName)
                eval(['recovered_trajectories.' tmp_markersName{m} ' = recovered.data(:,m:m+2);']);
            end
            clearvars m tmp_markersName
            
            % spatula blade corners:
            if strcmp(utensil.(trials{t}),'spatula')
                blade_corners = getSpatulaBlade(recovered_trajectories, recovered.nFrames, bladeCloseCorner,...
                    bladeLCloseCorner, bladeRfarCorner, bladeLfarCorner);
                
            % or tweezers' tips:
            else % if strcmp(utensil.(trials{t}),'tweezer')
                tips_position = getTweezersTips(recovered_trajectories, recovered.nFrames,...
                    tip_pos_arm_notcell, tip_pos_arm_cell);
            end
            
            
            % SAVE ALL ----------------------------------------------------------------------
            %       (i) complete/recovered markers trajectory
            %       (ii) trajectory of points of interest
            %       (iii) button signal
            
            if strcmp(utensil.(trials{t}),'spatula')
                folder = ['F:\C3D__files\S' num2str(s)]; % update path in case it was changed when trimming the C3D file
                save([folder '\' trials{t} '.mat'],'recovered_trajectories','blade_corners','button','start_frame')
            else
                folder = ['F:\C3D__files\S' num2str(s)]; % update path in case it was changed when trimming the C3D file
                save([folder '\' trials{t} '.mat'],'recovered_trajectories','tips_position','button','start_frame')
            end
            
        end
    end
end
clearvars s t original path_now



% recovered.data = [recovered.data blade_corners.Rclose blade_corners.Lclose blade_corners.Rfar blade_corners.Lfar];
% recovered.data = [recovered.data tips_position.arm_loadcell tips_position.arm_no_loadcell];
% % p.markercolors = [repmat([0 0 1],11,1); [1 0 1]]; % to have the tips in different colors
% myfighandle = figure;
% mc3dplot(recovered,p,myfighandle);












