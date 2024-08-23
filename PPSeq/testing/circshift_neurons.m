function shuffled_data = circshift_neurons(data, min_shift, max_shift)
    % data: Original dataset with neuron IDs and spike times
    % max_shift: Maximum time shift for circular shift

    shuffled_data = data;
    unique_neurons = unique(data.neuron_id);

    for i = 1:length(unique_neurons)
        neuron_id = unique_neurons(i);
        neuron_spike_times = data.spike_times(data.neuron_id == neuron_id);

        % Generate a random shift amount for each neuron
        shift_amount = randi([min_shift,max_shift]);

        % Apply circular shift
        shifted_spike_times = mod(neuron_spike_times + shift_amount, max(data.spike_times));

        shuffled_data.spike_times(data.neuron_id == neuron_id) = shifted_spike_times;
    end
end