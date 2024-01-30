nElements = 121;
DelayVector = zeros(1,nElements);

DelayMatrix = zeros(11,11);

d = [0 pi/4 pi/2 3*pi/4];

DelayMatrix(1,:) = [d(1) d(1) d(1) d(1) d(1) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(2,:) = [d(1) d(1) d(1) d(1) d(1) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(3,:) = [d(1) d(1) d(1) d(1) d(1) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(4,:) = [d(1) d(1) d(1) d(1) d(1) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(5,:) = [d(1) d(1) d(1) d(1) d(1) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(6,:) = [d(4) d(4) d(4) d(4) d(4) d(1) d(2) d(2) d(2) d(2) d(2)];

DelayMatrix(7,:) = [d(4) d(4) d(4) d(4) d(4) d(3) d(3) d(3) d(3) d(3) d(3)];

DelayMatrix(8,:) = [d(4) d(4) d(4) d(4) d(4) d(3) d(3) d(3) d(3) d(3) d(3)];

DelayMatrix(9,:) = [d(4) d(4) d(4) d(4) d(4) d(3) d(3) d(3) d(3) d(3) d(3)];

DelayMatrix(10,:) = [d(4) d(4) d(4) d(4) d(4) d(3) d(3) d(3) d(3) d(3) d(3)];

DelayMatrix(11,:) = [d(4) d(4) d(4) d(4) d(4) d(3) d(3) d(3) d(3) d(3) d(3)];

el_Stats = load("C:\Users\gv19838\OneDrive - University of Bristol\PhD\Verasonics\File_Share\Bristol arrays\Imasonic 2D matrix 121els 3.00MHz 1.00mm pitch.mat");
ElPos = zeros(121,2);
ElPos(:,1) = el_Stats.array.el_xc;
ElPos(:,2) = el_Stats.array.el_yc;
ElPos = ElPos*1e3;

%figure; scatter(ElPos(:,1),ElPos(:,2))

DelayVector = [];

for i = 11:-1:1
    DelayVector = [DelayVector,DelayMatrix(i,:)];
end

save('Barney/customDelayWS')
