function createCorrelationsOptStruct(ncells,varargin)
    % Define default values
    defaultBinning = 8;
    defaultCentralWindow = 5;
    defaultThrSpikes = 0;
    defaultNumRandomLags = 100;
    defaultTimePerRec = 600; % 10 min
    defaultSpikePath = fileSelector();
    
    % Set up the input parser
    p = inputParser;
    addParameter(p, 'binning', defaultBinning, ...
        @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'central_window', defaultCentralWindow, ...
        @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'thr_spikes', defaultThrSpikes, ...
        @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'num_random_lags', defaultNumRandomLags, ...
        @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'timePerRec', defaultTimePerRec, ...
        @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
    addParameter(p, 'spike_path', defaultSpikePath, ...
        @(x) ischar(x) || isstring(x));
    
    % Parse inputs
    parse(p, varargin{:});
    
    % Create the options structure
    opt = struct();
    opt.binning = p.Results.binning;
    opt.central_window = p.Results.central_window;
    opt.thr_spikes = p.Results.thr_spikes;
    opt.num_random_lags = p.Results.num_random_lags;
    opt.timePerRec = p.Results.timePerRec;
    opt.spike_path = p.Results.spike_path;
    opt.name = input('Enter name: ', 's');
    opt.pairs = nchoosek(1:ncells,2);
    
    % Save the structure to a file
    save(...
        fullfile( ...
            uigetdir, ...
            sprintf('opt_%s.mat', opt.name) ...
        ), ...
        'opt' ...
    );
end
