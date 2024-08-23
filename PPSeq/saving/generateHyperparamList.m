function hyperMat = generateHyperparamList(hyperCell)
    % Generate a matrix of all possible combinations of hyperparameters
    %
    % Inputs:
    %   hyperCell: Cell array where each cell contains a vector of possible values for a hyperparameter
    %
    % Outputs:
    %   hyperMat: Matrix where each row is a combination of hyperparameters
    %
    % The function also writes the resulting matrix to a file named 'hyperlist.txt'

    % Get the lengths of each hyperparameter vector
    lngths = cellfun(@length, hyperCell);

    % Generate grid of indices for all combinations of hyperparameter values
    [a, b, c, d, e] = ndgrid(1:lngths(1), 1:lngths(2), 1:lngths(3), 1:lngths(4), 1:lngths(5));
    paramOrder = sortrows([a(:), b(:), c(:), d(:), e(:)], 1);

    % Initialize hyperMat matrix
    hyperMat = zeros(size(paramOrder, 1), length(hyperCell));

    % Fill hyperMat with the corresponding hyperparameter values
    for i = 1:length(hyperCell)
        cur_param = hyperCell{i};
        hyperMat(:, i) = cur_param(paramOrder(:, i));
    end

    % Write the matrix of hyperparameters to a text file
    writematrix(hyperMat, 'hyperlist.txt', 'Delimiter', 'space');
end
