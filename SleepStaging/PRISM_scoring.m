
% PRISM_scoring.m
% July 8th, 2014

% TECHNICAL NOTE:
% This routine is aimed at clarifying the computational logic of the algorithm for automatic scoring of mouse sleep with a simplified Matlab implementation. 
% There are 3 input variables (eeg, emg, and samprate) and 1 output variable (MSCO).
% The following assumptions are made on the input variables: 
%	- eeg and emg include synchronized electroencephalographic and electromyographic signals, %	respectively, in the whole recording period.
%	- eeg and emg are structured as column vectors, each cell of which corresponds to one
%	sampling period (e.g., to 10 ms if the sampling rate is 100 Hz). 	
%        the length of the eeg and emg vectors is not limited by this routine. These vectors may be 
%	built starting, e.g., from .txt files using the “importdata” function or from .xls files using 
%        the “xlsread” function (built-in Matlab functions). The only limitation in applying this routine
%	concerns the computational power of the machine by which it is run. 
% 	- samprate is the sampling rate (in Hz) of the electroencephalographic and 
%	electromyographic signals, which is assumed to be the same.
%	- the duration of electroencephalographic and electromyographic recordings is assumed
%	 to be the same integer multiple of 4 s, which is the time resolution of sleep scoring
% 	in the present algorithm. This 4-s time unit will be referred to as epoch in the following 
% 	notes.

% TERMS OF USE:
% Users are free to adapt and apply this routine for research purposes provided that the source of 
%	the original routine and underlying algorithm is properly acknowledged by citation of this 
%	paper. 

% DISCLAIMER:
% This software routine is experimental in nature and is provided without any warranty of
%	merchantability or fitness for any purpose, or any other warranty expressed or implied. The %	Authors of this routine shall not be liable for any loss, claim or demand by any other party, %	due to or arising from the use of this software routine.

function MSCO = PRISM_scoring(eeg,emg,samprate)

%% Initialize vars
if not(isequal(size(eeg),size(emg)))
    error('the eeg and emg inputs have different size'); 
end

qseg = floor(length(eeg)/(samprate*4)); % number of 4-s data epochs in the recordings                      

eeg = eeg(1:samprate*4*qseg); emg = emg(1:samprate*4*qseg);

% initializes the matrix S, where each row corresponds to one epoch, in the output structure MSCO
MSCO.S = NaN(qseg,2);      

% initializes the matrix POW, where each row corresponds to one epoch, in the output structure 
% MSCO.  
MSCO.POW = NaN(qseg,81);

%% Calculate FFT
% nseg is a 4-s data epoch
for nseg = 1:qseg   

    % sigstart and sigstop are the cell positions in the eeg and emg vectors that correspond 
    %to the beginning and end of the epoch nseg, respectively.
	sigstart = (nseg - 1) * samprate * 4 + 1; 
    sigstop = nseg * samprate * 4;  

    % pow is the power spectral density of the electroencephalographic signal in the epoch nseg
    pow = (abs(fft(detrend(eeg(sigstart:sigstop)))).^2)/((samprate*4)^2)/(1/4); 
	pow = pow(2:floor(samprate*4/2)+1)*2; 

    % td is ratio between the electroencephalographic spectral power in the theta (6-9 Hz) and delta 
    %	(0.5-4 Hz) frequency ranges (theta/delta) computed in the epoch nseg 
    td = sum(pow(24:36))/sum(pow(2:16));                

    % em is the root mean square (emg rms) of the zero-mean electromyographic signal in the 
    %	epochnseg
	em = sqrt(mean(detrend(emg(sigstart:sigstop),'constant').^2));  

    % The values of td and em corresponding to the epoch nseg are copied to the corresponding row of
    % the matrix S
    MSCO.S(nseg,1:2) = [td em];                              

    % The first 80 columns of the matrix POW include the power spectral density of the 
    % electroencephalogram in the epoch nseg at frequencies from 0.25 Hz to 20 Hz (extremes 
    % included) at steps of 0.25 Hz. The 81st column is the total power spectral density of the 
    % electroencephalogram in the epoch nseg in the frequency range 0.25-20 Hz. 
    MSCO.POW(nseg,1:81) = [pow',sum(pow)];

end

%% Find high and low EMG cutoff values
% The variable emg5c in the output structure MSCO reflects the lowest emg rms values recorded. 
% This index is computed as the median of the 5th centile of	emg rms values.
emgsort = sort(MSCO.S(:,2)); 
MSCO.emg5c = median(emgsort(1:round(length(emgsort)/20)));

% The vector naxis spans the range of emg rms values from 0 to the 99th percentile of emg values 
%(variable maxnaxis) with a resolution coded in the naxisteps variable. A value of 3 for
% maxnaxis may be adequate when an electromyographic signal expressed in units of volts.
maxnaxis = prctile(MSCO.S(:,2),99);
naxisteps = maxnaxis/60; 
naxis = 0:naxisteps:maxnaxis;

% The vector naxis2 recodes naxis in units relative to the lowest emg rms values recorded. The
% variable naxis2 is useful for graphical representations because it is directly comparable among 
% experiments with different amplification of the electromyographic signal.
naxis2 = naxis/MSCO.emg5c;         

% The vector maxis spans the theta/delta ratio values from 0 to an empirically determined value of %	5, which is independent from electroencephalogram amplification. 
maxisteps =  5/100; 
maxis = 0:maxisteps:5;      

% Initializes the matrix Z in the output structure MSCO. The matrix Z will include the fraction of
%	epochs characterized by a given interval of theta/delta ratios (coded in the maxis vector and %	mapped to the rows of Z) and of emg rms values (coded in the naxis vector,  and mapped to
%	the columns of Z).
MSCO.Z = NaN(101,61);                                  
for n = 1:length(naxis)
    clc, disp(['computing 3D matrix, step ',mat2str(n),' of ',mat2str(length(naxis))])
    for m = 1:length(maxis)
        MSCO.Z(m,n) = sum(...
            MSCO.S(:,2) >= naxis(n) & ...
            MSCO.S(:,2) < (naxis(n) + naxisteps) & ...
            MSCO.S(:,1) >= maxis(m) & ...
            MSCO.S(:,1) < (maxis(m) + maxisteps))...
            / nseg;
    end
end

% The vector dens in the output structure MSCO includes the fraction of epochs characterized by
%	a given interval of emg rms values, which is coded in the naxis vector.
MSCO.dens = sum(MSCO.Z);                                         

% The variable cut_initial codes the first guess of the position of densi corresponding to the minimum
%	between modes of the densi variable. The value of 18 is adequate for cut_initial in cases with 2
%	modes of the densi variable. In cases with 3 modes of the densi variable, it may be
%	necessary to set the value of cut_initial so that it corresponds to a position between the highest
%	and the intermediate modes of the densi vector.
cut_initial = 18;                                            

maxlow = find(MSCO.dens(1:cut_initial) == max(MSCO.dens(1:cut_initial))); 
maxhigh = find(MSCO.dens(cut_initial+1:end) == max(MSCO.dens(cut_initial+1 : end))) + cut_initial;
bottom = find (MSCO.dens(maxlow:maxhigh) == min(MSCO.dens(maxlow:maxhigh)),1,'first') + maxlow - 1; 
[cutlow, cuthigh] = deal(bottom);

while abs((MSCO.dens(cutlow-1) - MSCO.dens(bottom)) / MSCO.dens(bottom)) < 0.20
	cutlow = cutlow-1; 
end

while abs((MSCO.dens(cuthigh+1) - MSCO.dens(bottom)) / MSCO.dens(bottom)) < 0.20
	cuthigh = cuthigh+1; 
end

% The vector emgcut in the output structure MSCO includes the lower and higher values of 
%	emg rms that define a boundary zone between the 2 modes (or between the highest and the 
%	intermediate modes) of the densi variable. The values of emgcut are defined arbitrarily as
%	the positions in the densi vector, which are nearest to the position defined by bottom, and
%	that have a value at least 20% higher than that at bottom. In turn, the bottom is computed 
%	based on the cuthyp variable.
MSCO.emgcut = [naxis(cutlow) naxis(cuthigh)];           

%% Compute initial scores
% Initializes the column vector auto, which will include the first step of automatic sleep scoring 
%	based only on local properties (theta/delta ratio, emg rms) of each epoch. The wake-sleep
%	state is scored as 1 (wakefulness), 2 (non-rapid-eye-movement sleep, NREMS), or 3 (rapid-
%	eye-movement sleep, REMS). Values of 10 and 20 indicate epochs with values of
%	theta/delta ratio and emg rms intermediate between wakefulness and NREMS or between
%	NREMS and REMS, respectively.
scores = NaN(nseg,1);                               

% wakefulness is scored when emg rms is above the boundary region defined by emgcut
scores(MSCO.S(:,2) > MSCO.emgcut(2)) = 1;       

% NREMS is scored when emg rms is below the boundary region defined by emgcut and the
%	theta/delta ratio is lower than 0.75. The latter condition indicates that
%	electroencephalographic spectral power in the delta frequency range is prevalent compared
%	with that in the theta frequency range.
scores(MSCO.S(:,2) < MSCO.emgcut(1) & MSCO.S(:,1) < 0.75) = 2;      

% REMS is scored when emg rms is below the boundary region defined by emgcut and the
%	theta/delta ratio is higher than 1.25. The latter condition indicates that
% 	electroencephalographic spectral power in the theta frequency range is prevalent compared
%	with that in the delta frequency range.
scores(MSCO.S(:,2) < MSCO.emgcut(1) & MSCO.S(:,1) > 1.25) = 3;      

% An epoch is considered as intermediate between wakefulness and NREMS (code 10) when its
%	emg rms value is included in the boundary region defined by emgcut.
scores(iswithin(MSCO.S(:,2), MSCO.emgcut(1), MSCO.emgcut(2))) = 10; 

% An epoch is considered as intermediate between NREMS and REMS (code 20) when the emg rms
%	is below the boundary region defined by emgcut and theta/delta ratio is between 0.75 and
%	1.25. The latter condition indicates that electroencephalographic spectral power in the delta
%	and theta frequency ranges are nearly equivalent.
scores(MSCO.S(:,2) < MSCO.emgcut(1) & iswithin(MSCO.S(:,1), 0.75, 1.25)) = 20; 


%% Correct scores
% Initializes the column vector scores_c, which includes the second and final step of automatic sleep
%	scoring. This step is based on local properties of each epoch, as elaborated in the auto
%	vector, but also takes into account information on the automatic scoring of adjacent epochs. 
%	Codes for wakefulness (1), NREMS (2) and REMS (3) are the same as in the vector auto. The
%	codes 10 and 20 used in the vector auto are replaced by either codes 1-3 or code 4, which
%	indicates an indeterminate state.
scores_c = scores;                                           

for n = 1:length(scores_c) - 3
    if scores_c(n) ~= 3
        continue
    else 
        clc
	    disp( ['phase one: progress ', mat2str(round (n/length(scores_c) * 100)) , ' %'])

        % Single epochs scored as either NREMS or indeterminate state (codes 10 or 20) are re-scored as
        % REMS in case they are preceded and followed by at least one REMS epoch 
        if ismember(scores_c(n + 1),[2 10 20]) && scores_c(n + 2) == 3
			scores_c(n+1) = 3;

        % Couple of epochs, which are both scored as indeterminate states (codes 10 or 20), or which are 
        %	scored as one epoch in indeterminate state and one epoch in NREMS, are re-scored as 2
        %	epochs of REMS in case they are preceded and followed by at least one REMS epoch.
        elseif sum (ismember(scores_c(n+1 : n+2), [2 10 20])) == 2 && ...
                sum (scores_c(n+1 : n+2) == 2) < 2 && ...
                scores_c(n+3) == 3
			scores_c(n+1 : n+2) = [3;3];

        end
    end
end

for n = 1:length(scores_c) - 3
    if scores_c(n) ~= 2
        continue
    else 
        clc
		disp(['phase two: progress ',mat2str(round(n/length(scores_c)*100)),' %'])

        % Single epochs scored as either REMS or indeterminate state (codes 10 or 20) are re-scored as
        % 	NREMS in case they are preceded and followed by at least one NREMS epoch 
        if ismember(scores_c(n+1),[3 10 20]) && scores_c(n+2) == 2
	        scores_c(n+1) = 2;

        % Epochs scored as indeterminate state (code 20) are confirmed as such (code 4) in case they are
        %	preceded by at least one NREMS epoch and followed by at least 2 REMS epochs
       	elseif scores_c(n+1) == 20 && scores_c(n+2)==3 && scores_c(n+3) == 3
			scores_c(n+1) = 4;

        % Couple of epochs, which are both scored as indeterminate states (codes 10 or 20), or which are
        %	scored as one epoch in indeterminate state and one epoch in REMS, are re-scored as 
        % 	epochs of NREMS in case they are preceded and followed by at least one epoch of NREMS.
        elseif sum (ismember (scores_c(n+1:n+2), [3 10 20] )) == 2 && sum(scores_c(n+1:n+2) == 3) < 2 && scores_c(n+3) == 2
			scores_c(n+1:n+2) = [2;2];

        end
    end
end


% Epochs that after the previous substitutions remain scored as indeterminate state are re-scored as
%	NREMS, if their previous code was 20, or are confirmed as indeterminate state (code 4), if
%	their previous code was 10.
scores_c((scores_c == 20)) = 2; 
scores_c((scores_c == 10)) = 4;

for n = 1:length(scores_c) - 3
    if scores_c(n) ~= 1
        continue
    else 
        clc
		disp(['phase three: progress ',mat2str(round(n/length(scores_c)*100)),' %'])

        % Epochs scored as NREMS, REMS, or indeterminate state (code 4) are re-scored as wakefulness in
        %	case they are preceded by at least one epoch of wakefulness.
        if (ismember(scores_c(n+1),[2 3 4]) && scores_c(n+2) == 1)
			scores_c(n+1) = 1;

        % Epochs scored as REMS are re-scored as indetermined state (code 4) in case they are preceded by
        %	at least one epoch of wakefulness and followed by at least one epoch of NREMS
        elseif (scores_c(n+1)==3 && scores_c(n+2) == 2)
			scores_c(n+1) = 4;

        % Couples of epochs, which are scored as either NREMS, REMS, or indeterminate states (code 4) in
        %	any combination, are re-scored as indeterminate state (code 4) in case they are preceded and
        %	followed by at least one epoch of wakefulness.
        elseif sum(ismember(scores_c(n+1:n+2),[2 3 4])) == 2 && scores_c(n+3) == 1
			scores_c(n+1:n+2) = [4;4];

        end
    end
end

% The vector idx_rem indicates the position of the cells in the vector auto2, which are scored as
%	REMS (code 3)
idx_rem = find(scores_c == 3);

% If an isolated epoch is scored as REMS, and if its adjacent epochs are scored in the same state,
%	and if such a state is different from REMS, that epoch is re-scored with the same state as its
%	adjacent epochs.
if not(isempty(idx_rem))
    for n = 1:length(idx_rem)
        if scores_c(max(1, idx_rem(n) - 1)) ~= 3 && ...
                scores_c(max(1,idx_rem(n)-1)) == scores_c(min(nseg,idx_rem(n)+1))
            scores_c(idx_rem(n)) = scores_c(max(1,idx_rem(n)-1));
        end
    end
end

% Indetermined states in the auto vector (codes 10 and 20) are attributed the code 4, for the sake of
%	consistency and comparison with the auto2 vector
scores((scores==10 | scores==20)) = 4;

% Copies the vectors auto and auto2 in the third and fourth columns, respectively, of the matrix S
MSCO.S(:,3) = scores; 
MSCO.S(:,4) = scores_c;

% The matrix znew is a copy of the matrix Z, but with null values substituted by NaNs for the
%	purpose of graphical representation.
znew = MSCO.Z; 
znew(znew==0)=NaN;


%% Plot figures
% Figure 1 plots the matrix Z as a 3D graph
figure(1)
set(gcf,'Renderer','zbuffer')
surf(naxis2,maxis,log10(znew)), shading interp, colormap ('jet')
xlabel('emgrms normalized'), ylabel('eeg theta vs. delta ratio'), zlabel('fraction of epochs')

%powtot is a matrix built with the same logic of MSCO.POW. The power spectral density values
% reported in the 81 columns of powtot correspond to the average values calculated during 
% wakefulness (first row), %%NREMS (second row) or REMS (third row).
figure(2)
powtot= zeros(3,80).*NaN;
powtot(1,1:80)= mean(MSCO.POW(MSCO.S(:,4)==1,1:80));
powtot(2,1:80)= mean(MSCO.POW(MSCO.S(:,4)==2,1:80));
powtot(3,1:80)= mean(MSCO.POW(MSCO.S(:,4)==3,1:80));

% Figure 2 plots the mean power spectral density (units^2/Hz) during wakefulness (red line),
% NREMS (green line) and REMS (blue line) in the frequency range 0.25-20 Hz. 
asX = 0.25 : 0.25 : 20;
plot(asX,powtot(1,:),'r',asX,powtot(2,:),'g',asX,powtot(3,:),'b')
xlabel('Frequency (Hz)'); ylabel('EEG Power Spectral Density (units^2/Hz)');

% Figure 3 plots the matrix densi as a 2D graph, and marks the limits of the boundary zone between
%	the higher and lower modes of the densi variable. If the variable densi has 3 modes, users
%	should check on figure 3 whether the boundary zone is correctly positioned between the
%	highest mode and the intermediate mode. If this is not the case, the whole scoring routine
%	should be repeated after setting the value of the variable cuthyp to any position of the densi 
%	vector that is intermediate between the positions of the highest and the
%	intermediate modes.
figure(3)
plot(naxis2,MSCO.dens,'rs',naxis2(cutlow),MSCO.dens(cutlow),'ks',naxis2(cuthigh),MSCO.dens(cuthigh),'ks')
xlabel('emgrms normalized'), ylabel('fraction of epochs')


%% Assess EEG quality
% The vector idx_rem indicates the position of the rows in the matrix S, which are scored as REMS
%	(coded 3 in column 4, corresponding to the final step of automatic scoring).
idx_rem = find(MSCO.S(:,4) == 3);

% The variable rem_lowtd is the fraction of REMS epochs with a theta/delta ratio lower than 2.5
rem_lowtd = length(find(MSCO.S(idx_rem,1) > 2.5))/length(idx_rem);

% If qremtd is lower than 0.1, users are warned that the automatic sleep scoring may be inadequate
%	because of problems with quality of the raw electroencephalogram 
if rem_lowtd < 0.1
	disp('WARNING: less than 10% of REMS epochs have a theta/delta EEG power ratio 	higher than 2.5');
    	disp('this indicates that the quality of the raw EEG signal is insufficient for automatic sleep scoring')
    	disp('Manual sleep scoring is thus recommended for this record')
end


