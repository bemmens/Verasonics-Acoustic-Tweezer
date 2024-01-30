%{
Ri = 24.5e-3;
Ro = 30.5e-3;
Rc = sqrt((Ro^2 + Ri^2)/2); % geometric mean
nElements = 32;

elementSpacing_rad = 2*pi/nElements;

elementIds = 1:nElements;
elementCoords = zeros(nElements,5); % theta, r
elementCoordsCart = zeros(nElements,2); % x, y

for i = elementIds
    elementCoords(i,:) = [Ri, Ro, Rc, 0, (i-1)*elementSpacing_rad];
    [elementCoordsCart(i,1),elementCoordsCart(i,2)] = pol2cart(elementCoords(i,5),elementCoords(i,3));
end

scatter(elementCoordsCart(:,1),elementCoordsCart(:,2))

save("Barney/elementCoords_Ring","elementCoordsCart")

%}

Ri = 24.5e-3;
Ro = 30.5e-3;
%Rc = sqrt((Ro^2 + Ri^2)/2); % geometric mean centre
Rc = (Ri+Ro) / 2;
nElements = 32;

elementSpacing_rad = 2*pi/nElements;

elementIds = 1:nElements;
elementCoordsCart = zeros(nElements,5); % x, y, elevation

for i = elementIds
    elementCoordsCart(i,5) = (i-1)*elementSpacing_rad;
    [elementCoordsCart(i,1),elementCoordsCart(i,2)] = pol2cart(elementCoordsCart(i,5),Rc);
end

scatter(elementCoordsCart(:,1),elementCoordsCart(:,2))
pbaspect([1 1 1])

save("Barney/elementCoords_Ring","elementCoordsCart")