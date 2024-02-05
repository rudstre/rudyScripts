
clear all; close all; clc

read_Intan_RHD2000_file

data = amplifier_data; clear amplifier_data;

%%

clear y s f t p power freq
for ch = 1: 128
    temp_1 = decimate(data(ch,:),5,4);
    temp_2 = decimate(temp_1,5,4);
    y(ch,:) = decimate(temp_2,4,4);
    
    [s(:,:,ch),f{ch},t{ch},p(:,:,ch)] = spectrogram(y(ch,:),1000,200,[],200,'yaxis');
    
    [power(ch,:),freq(ch,:)] = pspectrum(y(ch,:),200);
    ch
end

%%
mean_p_chip1 = mean(p(:,:,1:64),3);
mean_p_chip2 = mean(p(:,:,65:128),3);

mean_power_chip1 = mean(10*log10(power(1:64,:)),1);
mean_power_chip2 = mean(10*log10(power(65:128,:)),1);

figure(1);
subplot(2,1,1);
imagesc(t{1}, f{1}, 10*log10(mean_p_chip1+eps)) % add eps like pspectrogram does
hold on;
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (s)')
h = colorbar;
h.Label.String = 'Power/frequency (dB/Hz)';
axis tight
ylim([0 50]);
caxis([0 50])
hold off
title('chip 1')

subplot(2,1,2);
hold on
imagesc(t{1}, f{1}, 10*log10(mean_p_chip2+eps)) % add eps like pspectrogram does
axis xy
ylabel('Frequency (Hz)')
xlabel('Time (s)')
h = colorbar;
h.Label.String = 'Power/frequency (dB/Hz)';
axis tight
ylim([0 50]);
caxis([0 50])
hold off
title('chip 2')

[~,ind] = (min(abs(freq(1,:)-15)));
low_freq = 1:ind;
figure(2)
plot(freq(1,low_freq),mean_power_chip1(low_freq),'k')
hold on
plot(freq(1,low_freq),mean_power_chip2(low_freq),'r')
hold off
box off
ylabel('power')
xlabel('freq')
legend('chip 1','chip2')


%%
figure();
spectrogram(y(70,:),1000,200,[],200,'yaxis')
ylim([0 50]);







