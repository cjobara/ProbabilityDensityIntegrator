
% Expected Value Calculator

% Output Excel files are padded with a row of zeros at the top to keep
% later programs from truncating the data. If not using my code,make sure
% you remove these before dowstream processing!

% NOTE: This will only work in this implementation for observables that are
% independent of variations in theta. You'll need to nest this inside the
% Radial probability calculator program if r and theta are inseperable
% variables.

condition=char(reds(a));

Files=dir(fullfile(pwd, '*densities.mat')); 

[NumFiles,~]=size(Files);
    
files={Files.name};

RawDensity=zeros(1140, 2, NumFiles);

NormDensity=zeros(1140, 2, NumFiles);

r_bar_raw=zeros(NumFiles+1,2);
dI_dr_raw=zeros(NumFiles+1,2);

r_bar_cyto=zeros(NumFiles+1,2);
r_bar_total=zeros(NumFiles+1,2);
dI_dr_cyto=zeros(NumFiles+1,2);
dI_dr_total=zeros(NumFiles+1,2);

OutFile1=(strcat(condition,'_stats1.xlsx'));
%If running on PC, comment out the two below and change the xlswrite lines
%at the end to all be in the same file. On mac have to use this...
%OutFile2=(strcat(condition,'_stats2.xlsx'));
%OutFile3=(strcat(condition,'_stats3.xlsx'));


for i=1:NumFiles
    
    % Record the name of the file
    filename=char(files(i));
    load(filename);
    
    RawDensity(1:size(RawProbDensity,1),:,i)=RawProbDensity(:,1:2);
    NormDensity(1:size(RawProbDensity,1),:,i)=StrappedProbDensity(:,1:2);
    
    r=(0.05*(1:size(RawProbDensity,1))).';
    
    r_bar_raw(i+1,:)=sum(bsxfun(@times, r, RawProbDensity),1);
    dI_dr_raw(i+1,:)=sum(abs(diff(RawProbDensity)),1);
    
    rp=((1:size(RawProbDensity,1))*125/size(RawProbDensity,1)-25).';
    EnvIndex=size(RawProbDensity,1)/5;
    CytoIndex=size(RawProbDensity,1);
    rp_prob=bsxfun(@times,rp,StrappedProbDensity);
    
    r_bar_cyto(i+1,:)=sum(rp_prob(EnvIndex:CytoIndex,:),1);
    r_bar_total(i+1,:)=sum(bsxfun(@times,rp,StrappedProbDensity));
    dI_dr_cyto(i+1,:)=sum(abs(diff(StrappedProbDensity(EnvIndex:CytoIndex,:),1)));
    dI_dr_total(i+1,:)=sum(abs(diff(StrappedProbDensity)),1);
    
end

OutArray1=[r_bar_raw, dI_dr_raw];
OutArray2=[r_bar_cyto, r_bar_total, dI_dr_cyto, dI_dr_total];
OutArray3= [mean(RawDensity,3), mean(NormDensity,3)];

save(strcat(condition,'_data'), 'RawDensity', 'NormDensity','-v7.3'  );
    
xlswrite(OutFile1, OutArray1, 1);
xlswrite(OutFile1, OutArray2, 2);%2 for third index if on PC
xlswrite(OutFile1, OutArray3, 3);%3 for third index if on PC