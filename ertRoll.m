%this script merges ERT roll-along files
%
clear all; close all; clc
sep = 4; %enter electrode separation
minVal = 0.0001; %minimum transfer resistance value to retain

files = dir([pwd '\data']);
for i = 3:length(files) %start at 5 to ignore the non-data files
    d = importAGI([pwd '\data\' files(i).name]); %uses the nested function at the bottom of this script to import SuperSting
    data{i-2} = [(d(:,10)./sep)+1 (d(:,13)./sep)+1 (d(:,16)./sep)+1 (d(:,19)./sep)+1 d(:,5)];% A B M N R
    clear d
end
data(cellfun(@isempty,data))=[];

merged = data{1};
for j = 1:length(data)
    merged = [merged; data{j}];
end
merged(:,1:4) = (merged(:,1:4)-min(min(merged(:,1:4))))+1;

%% clen up negative or NaN values
dat_a = sortrows(merged,5); %sort based on coluclcm that will have NaNs
firstD = max(find(dat_a(:,5)<minVal))+1; %finds the last negative val, +1 for first positive value. used to delete negative R vals
lastD = find(~isnan(dat_a(:,5)),1,'last'); %finds the begning of the NaN rows to delete

merged = dat_a(firstD:lastD,:); %take only rows >0 and without NaN R values

%% assemble r2 protocol.dat
out = zeros(1,5);
radUnc = zeros(1,2);
out = [out; merged(:,1:5)];
nums = 1:length(out)-1;
out = [nums' out(2:end,:)];
dataNumber=max(nums);
protocolData = [out];
newfile = [pwd '/protocol.dat'];
dlmwrite(newfile,dataNumber)
dlmwrite(newfile,protocolData,'-append','delimiter','\t')
clear newfile;
fprintf('protocol.dat written\n')


% nested functions only below here
function d = importAGI(filename)

% Initialize variables.
delimiter = ',';
if nargin<=2
    startRow = 4;
    endRow = inf;
end

% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

% Open the text file.
fileID = fopen(filename,'r');

% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

% Close the text file.
fclose(fileID);

% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = [dataArray{:,1:end-1}];
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;

            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

% Create output variable
d = cell2mat(raw);
end