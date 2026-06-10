function delay = addHybridFocus(elementPosMm,focusPointMm,lensFocusPointMm,k)
% elementPosMm: Nx3 array of element positions in millimeters
% focusPointMm: 1x3 or 3x1 vector of desired focus point in millimeters
% lensFocusPointMm: 1x3 or 3x1 vector of lens focus point in millimeters
% k: scalar scaling factor

elementPos = elementPosMm./1000; % convert to meters
focusPoint = focusPointMm./1000; % convert to meters
lensFocusPoint = lensFocusPointMm./1000; % convert to meters

r = sqrt((elementPos(:,1)-focusPoint(1)).^2+(elementPos(:,2)-focusPoint(2)).^2 + (elementPos(:,3)-focusPoint(3)).^2); % Nx1 vector of distances from each element to focusPoint
r_lens = sqrt((elementPos(:,1)-lensFocusPoint(1)).^2+(elementPos(:,2)-lensFocusPoint(2)).^2 + (elementPos(:,3)-lensFocusPoint(3)).^2); % Nx1 vector of distances from each element to lensFocusPoint
delay = k*(r - r_lens)'/(2*pi); % Nx1 vector of scaled relative delays

delay = delay - min(delay); % Shift delays so that the minimum delay is zero
end
