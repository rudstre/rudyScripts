% plot the impedance values
clear all; close all; clc

read_Intan_RHD2000_file

imp_kOhms = cell2mat({amplifier_channels.electrode_impedance_magnitude})'./(1e3);

figure(1)
semilogy(imp_kOhms,'*k','markersize',10)
hold on
plot([1 128],200*ones(1,2),'r')
plot([1 128],1e3*ones(1,2),'r')
plot([64 64],[1 1e5],'b')
ylabel('kOhms')
xlabel('channel')
box off