%% EXAMPLE

% add mocap toolboxes to searched paths
addpath(genpath('MocapRecovery-master'))


% load one of the data files (MAT) with the tweezers' tips or spatula blade
load('VICON_spatula\chef_S1\S1_spatula_chic1_m1.mat')


matrix = [];

markers_name = fieldnames(recovered_trajectories);
for i=1:length(markers_name)
    matrix = [matrix recovered_trajectories.(markers_name{i})];
end

if exist('tips_position','var')
    matrix = [matrix tips_position.arm_loadcell tips_position.arm_no_loadcell];
else
    matrix = [matrix blade_corners.Lclose blade_corners.Lfar blade_corners.Rfar blade_corners.Rclose];
end
    

p = mcinitanimpar;

if exist('tips_position','var')
    idx.c_long = find(strcmp(markers_name,'c_long'));   %   or  tweezers:c_long
    idx.a_long = find(strcmp(markers_name,'a_long'));   %   ...
    
    idx.c_far = find(strcmp(markers_name,'c_far'));
    idx.a_far = find(strcmp(markers_name,'a_far'));
    
    idx.c_short = find(strcmp(markers_name,'c_short'));
    idx.a_short = find(strcmp(markers_name,'a_short'));
    
    idx.c_tipL =  find(strcmp(markers_name,'c_tiplong'));
    idx.c_tipO =  find(strcmp(markers_name,'c_tipother'));
    
    p.conn = [idx.c_long,idx.c_far;   idx.c_far,idx.c_short;   idx.c_short,idx.c_long;...
        idx.a_long,idx.a_far;   idx.a_far,idx.a_short;   idx.a_short,idx.a_long;...
        idx.c_tipL,idx.c_tipO;  idx.c_long,idx.c_tipL;    idx.c_short,idx.c_tipO;...
        idx.a_short,idx.c_tipL;    idx.a_long,idx.c_tipO];
else
    idx.sUp = find(strcmp(markers_name,'sUp'));   %  or  spatula:sUp
    idx.sR = find(strcmp(markers_name,'sR'));     %  ...
    idx.sClose = find(strcmp(markers_name,'sClose'));
    idx.sFar = find(strcmp(markers_name,'sFar'));
    
    idx.hUpR = find(strcmp(markers_name,'hUpR'));
    idx.hDownL = find(strcmp(markers_name,'hDownL'));
    
    idx.hUpL =  find(strcmp(markers_name,'hUpL'));
    idx.hDownR =  find(strcmp(markers_name,'hDownR'));
    
    p.conn = [idx.sUp,idx.sClose;   idx.sUp,idx.sFar;   idx.sR,idx.sUp;...
        idx.hDownR,idx.hDownL;   idx.hUpL,idx.hUpR;...
        idx.hUpL,idx.hDownL;  idx.hUpR,idx.hDownR; 12 13; 13 14; 14 15; 15 12];
end

markers.data = matrix;
markers.nFrames = size(markers.data,1);

myfighandle = figure;
mc3dplot(markers,p,myfighandle);


%%

% close all
% clear all






