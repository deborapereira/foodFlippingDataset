
folder1 = 'E:\DATA\foodTracking\chef\';
folder2 = 'E:\DATA\foodTracking\notchef\';

files1 = dir([folder1 '*.csv']);
files2 = dir([folder2 '*.csv']);



% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 12);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["iteration", "frame_num", "obj_ID", "obj_cat", "obj_pos_x", "obj_pos_y", "obj_area", "startX", "startY", "endX", "endY", "score"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
files_nb = length(files1)+length(files2);
csv_data = cell(files_nb,1);
for i=1:length(files1)
    csv_data{i} = readtable([folder1 files1(i).name], opts);
end
for j=1:length(files2)
    csv_data{i+j} = readtable([folder2 files2(j).name], opts);
end

clear opts i j files1 files2 folder1 folder2

%% check that all data is available
NaNs=zeros(files_nb,1);
for k=1:files_nb
    NaNs(k) = sum(sum(isnan(table2array(csv_data{k}))));
end
% RESULTS: no NaN value was found among the csv data files, so they should
%          be all ok in terms of integrity.




