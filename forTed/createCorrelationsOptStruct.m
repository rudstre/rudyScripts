function opt = createCorrelationsOptStruct(pairs,recLen,varargin)
% Define default values
defaultBinning = 8;
defaultCentralWindow = 5;
defaultThrSpikes = 0;
defaultNumRandomLags = 100;
defaultTimePerRec = minutes(10);
defaultSpikePath = '';
defaultSavePath = '';
defaultMaxLag = 100;

% Set up the input parser
p = inputParser;
addRequired(p, 'pairs');
addRequired(p, 'recLen');
addParameter(p, 'binning', defaultBinning, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
addParameter(p, 'central_window', defaultCentralWindow, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
addParameter(p, 'thr_spikes', defaultThrSpikes, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
addParameter(p, 'num_random_lags', defaultNumRandomLags, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
addParameter(p, 'timePerRec', defaultTimePerRec, @(x) validateattributes(x, {'duration'}));
addParameter(p, 'max_lag', defaultMaxLag, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
addParameter(p, 'spike_path', defaultSpikePath, @(x) ischar(x) || isstring(x));
addParameter(p, 'save_path', defaultSavePath, @(x) ischar(x) || isstring(x));

% Parse inputs
parse(p, pairs, recLen, varargin{:});

% Create the options structure
opt = struct();
opt.pairs = pairs;
opt.binning = p.Results.binning;
opt.nsessions = ceil(recLen/p.Results.timePerRec);
opt.central_window = p.Results.central_window;
opt.thr_spikes = p.Results.thr_spikes;
opt.num_random_lags = p.Results.num_random_lags;
opt.timePerRec = p.Results.timePerRec;
opt.spike_path = p.Results.spike_path;
opt.max_lag = p.Results.max_lag;
if isempty(opt.spike_path), opt.spike_path = uigetdir(); end
opt.save_path = p.Results.save_path;
if isempty(opt.save_path), opt.save_path = uigetdir(); end
opt.name = input('Enter name: ', 's');

% Save the structure to the specified save path
opt_path = fullfile(uigetdir, sprintf('opt_%s.mat', opt.name));
save(opt_path,'opt');

% Print a detailed summary to the user
fprintf('\n=========== Options Summary ===========\n');
fprintf('Name: %s\n', opt.name);
fprintf('Spike Path (Cluster): %s\n', opt.spike_path);
fprintf('Save Path: %s\n', opt.save_path);
fprintf('Binning: %d\n', opt.binning);
fprintf('Central Window: %d\n', opt.central_window);
fprintf('Max Lag: %d\n', opt.max_lag);
fprintf('Threshold Spikes: %d\n', opt.thr_spikes);
fprintf('Number of Random Lags: %d\n', opt.num_random_lags);
fprintf('Time per Session: %2.1f minutes\n', minutes(opt.timePerRec));
fprintf('Number of Sessions: %d\n', opt.nsessions);
fprintf('Options saved to: %s\n', opt_path);
fprintf('=======================================\n\n');
end