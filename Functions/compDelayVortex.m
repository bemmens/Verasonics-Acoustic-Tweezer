function [phaseDelayVector,phaseDelayMatrix] = compDelayVortex(elementPos,shape)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
nElements = length(elementPos);
size = sqrt(nElements);
phaseDelayVector = atan2(elementPos(:,1),elementPos(:,2));
phaseDelayVector = (phaseDelayVector-min(phaseDelayVector))/(2*pi);
if shape == 1
    phaseDelayMatrix = reshape(phaseDelayVector,size,size);
else
    phaseDelayMatrix = nan;
end
end