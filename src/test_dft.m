%Test script for mocalc()
%%
%Load in true values
clear; clc;
load('testcases_v04');


%%
%Do a single run
clc;
numTest = 15;
options = struct('basisset', testcase(numTest).Basis,...
                 'tolEnergy', 1e-8,...
                 'tolDensity', 1e-8,...
                 'Method', 'KS',...
                 'ExchFunctional', 'Slater',...
                 'CorrFunctional', 'VWN5',...
                 'nRadialPoints', 45,...
                 'nAngularPoints', 302);
             
out = mocalc(testcase(numTest).Elements, testcase(numTest).xyz,...
         testcase(numTest).TotalCharge, options);