function delay = addFocus(elementPosMm,focusPointMm,k)
elementPos = elementPosMm./1000; % convert to meters
focusPoint = focusPointMm./1000; % convert to meters
r = sqrt((elementPos(:,1)-focusPoint(1)).^2+(elementPos(:,2)-focusPoint(2)).^2 + (elementPos(:,3)-focusPoint(3)).^2);
delay = (k*r)'./(2*pi);
delay = delay - min(delay); % Shift delays so that the minimum delay is zero

end
