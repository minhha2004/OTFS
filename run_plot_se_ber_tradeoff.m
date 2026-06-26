% Post-processing script for Chapter 5.
% Run this after all selected (n,k) configurations have been simulated and
% saved in the results folder. It does not rerun Monte Carlo simulation.

clear;
clc;
close all;

addpath('config');
addpath('detectors');
addpath('pattern_selection');
addpath('reporting');
addpath('simulation');
addpath('utils');

plot_se_ber_tradeoff_from_results([], [10 15], 'results');
