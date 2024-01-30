clear all

%% Generate Resource
Resource.Parameters.numTransmit = 32; % no. of transmit channels
Resource.Parameters.connector = 1; % trans. connector to use (V 256).
Resouce.Parameters.speedOfSound = 1481;

%% Generate Trans
load Trans_Ring
