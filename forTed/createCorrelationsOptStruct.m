function createCorrelationsOptStruct(varargin)
    % Define default values
    defaultPairs = 'pairs';
    defaultBinning = 8;
    defaultCentralWindow = 5;
    defaultThrSpikes = 0;
    defaultNumRandomLags = 100;
    defaultTimePerRec = 600;
    defaultSpikePath = fileSelector();
    defaultSavePath = fileSelector();

    % Set up the input parser
    p = inputParser;
    addParameter(p, 'pairs', defaultPairs);
    addParameter(p, 'binning', defaultBinning, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'central_window', defaultCentralWindow, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'thr_spikes', defaultThrSpikes, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'num_random_lags', defaultNumRandomLags, @(x) validateattributes(x, {'numeric'}, {'scalar', 'nonnegative'}));
    addParameter(p, 'timePerRec', defaultTimePerRec, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
    addParameter(p, 'spike_path', defaultSpikePath, @(x) ischar(x) || isstring(x));
    addParameter(p, 'save_path', defaultSavePath, @(x) ischar(x) || isstring(x));

    % Parse inputs
    parse(p, varargin{:});

    % Create the options structure
    opt = struct();
    opt.pairs = p.Results.pairs;
    opt.binning = p.Results.binning;
    opt.central_window = p.Results.central_window;
    opt.thr_spikes = p.Results.thr_spikes;
    opt.num_random_lags = p.Results.num_random_lags;
    opt.timePerRec = p.Results.timePerRec;
    opt.spike_path = p.Results.spike_path;
    opt.save_path = p.Results.save_path;
    opt.name = input('Enter name: ', 's');

    % Save the structure to the specified save path
    save(...
        fullfile( ...
            opt.save_path, ...
            sprintf('opt_%s.mat', opt.name) ...
        ), ...
        'opt' ...
    );
end
