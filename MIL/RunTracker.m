%%
% Demo for paper--Kaihua Zhang, Huihui song, 'Real-time Visual Tracking via
% Online Weighted Multiple Instance Learning', Pattern Recongtion.
% Author: Kaihua Zhang, Dept. of Computing, HK PolyU.
% Email: zhkhua@gmail.com
% Date: 8/8/1011
%%
clc;clear all;close all;
data_path = 'd:/TrackingPerformance/data/';


dirs = dir(data_path);
videos = {dirs.name};
videos(strcmp('.', videos) | strcmp('..', videos) | ...
    strcmp('anno', videos) | ~[dirs.isdir]) = [];

%the 'Jogging' sequence has 2 targets, create one entry for each.
%we could make this more general if multiple targets per video
%becomes a common occurence.
% 		videos(strcmpi('Jogging', videos)) = [];
% 		videos(end+1:end+2) = {'Jogging.1', 'Jogging.2'};

max_threshold = 50;  %used for graphs in the paper
all_precisions = zeros(numel(videos),max_threshold);  %to compute averages
all_fps = zeros(numel(videos),1);        
%videos{1} = 'Tracjectory10';
videos = '';
videos{1} = 'Tracjectory16';
for k = 1:numel(videos),
    
    rand('state',0);% 
    time = 0;

    %----------------------------------
    % The video sequences can be download from Boris's homepage
    % http://vision.ucsd.edu/~bbabenko/project_miltrack.shtml
    %----------------------------------
    %----------------------------------
    addpath(sprintf('%s%s/',data_path,videos{k}));
    %----------------------------------
    load groundtruth_rect.txt;
    initstate = groundtruth_rect(1,:);%initial tracker
    %----------------------------Set path
    img_dir = dir(sprintf('%s%s/img/*.jpg',data_path,videos{k}));
    %-----------------------------The object position in the first frame
    % x = initstate(1);% x axis at the Top left corner
    % y = initstate(2);% y axis at the Top left corner
    % w = initstate(3);% width of the rectangle
    % h = initstate(4);% height of the rectangle
    num = length(img_dir);% number of frames
    %% Parameter Settings

    trparams.init_negnumtrain = 50;%number of trained negative samples
    trparams.init_postrainrad = 4.0;%radical scope of positive samples; boy 8
    trparams.initstate = initstate;% object position [x y width height]
    trparams.srchwinsz = 25;% size of search window; boy 35
    %-------------------------
    % classifier parameters
    clfparams.width = trparams.initstate(3);
    clfparams.height= trparams.initstate(4);
    %-------------------------
    % feature parameters:number of rectangle
    ftrparams.minNumRect = 2;
    ftrparams.maxNumRect = 4;
    %-------------------------
    lRate = 0.85;% learning rate parameter ; 0.7 for biker1
    %-------------------------
    M = 150;% number of all weak classifiers in feature pool
    numSel = 15; % number of selected weak classifier 
    %-------------------------Initialize the feature mean and variance
    posx.mu = zeros(M,1);% mean of positive features
    negx.mu = zeros(M,1);
    posx.sig= ones(M,1);% variance of positive features
    negx.sig= ones(M,1);
    %-------------------------
    %compute feature template
    [ftr.px,ftr.py,ftr.pw,ftr.ph,ftr.pwt] = HaarFtr(clfparams,ftrparams,M);
    %% initilize the first frame
    %---------------------------
    img = imread(sprintf('%s%s/img/%s',data_path,videos{k},img_dir(1).name));
    img = double(img(:,:,1));
    [rowz,colz] = size(img);
    %---------------------------
    %compute sample templates
    posx.sampleImage = sampleImg(img,initstate,trparams.init_postrainrad,0,100000);
    negx.sampleImage = sampleImg(img,initstate,2*trparams.srchwinsz,1.5*trparams.init_postrainrad,trparams.init_negnumtrain);
    %--------extract haar features
    iH = integral(img);%Compute integral image
    selector = 1:M;% select all weak classifier in pool
    posx.feature = getFtrVal(iH,posx.sampleImage,ftr,selector);
    negx.feature = getFtrVal(iH,negx.sampleImage,ftr,selector);
    %--------Update the weak classifiers
    [posx.mu,posx.sig,negx.mu,negx.sig] = weakClfUpdate(posx,negx,posx.mu,posx.sig,negx.mu,negx.sig,lRate);% update distribution parameters
    posx.pospred = weakClassifier(posx,negx,posx,selector);% Weak classifiers designed by positive samples
    negx.negpred = weakClassifier(posx,negx,negx,selector);% ... by negative samples
    %----------------------------------------------weight of the positive instance   
    posx.w = exp(-((posx.sampleImage.sx-initstate(1)).^2+(posx.sampleImage.sy-initstate(2)).^2));
    %-----------------------------------Feature selection
    selector = clfWMilBoostUpdate(posx,negx,numSel);
    %--------------------------------------------------------
    %% Start tracking
    positions = [initstate];

    for i = 2:num
        img1 = imread(sprintf('%s%s/img/%s',data_path,videos{k},img_dir(i).name));
        img = double(img1(:,:,1));% Only utilize one channel of image
        tic()
        detectx.sampleImage = sampleImg(img,initstate,trparams.srchwinsz,0,100000);
        iH = integral(img);%Compute integral image
        detectx.feature = getFtrVal(iH,detectx.sampleImage,ftr,selector);
        %----------------------------------
        r = weakClassifier(posx,negx,detectx,selector);% compute the classifier for all samples
        prob = sum(r);% linearly combine the weak classifier in r to the strong classifier prob
        %-------------------------------------
        [c,index] = max(prob);
        %-------------------------------------
        x = detectx.sampleImage.sx(index);
        y = detectx.sampleImage.sy(index);
        w = detectx.sampleImage.sw(index);
        h = detectx.sampleImage.sh(index);
        initstate = [x y w h];
        positions = [positions;initstate];
        %-----------------------------------------Show the tracking result
         himg = imshow(uint8(rgb2gray(img1)));
         rectangle('Position',initstate,'LineWidth',2,'EdgeColor','r');
         text(5, 18, strcat('#',num2str(i)), 'Color','y', 'FontWeight','bold', 'FontSize',20);
         set(gca,'position',[0 0 1 1]); 
         saveas(himg,sprintf('results/human/%04d.png',i),'png');
         pause(0.00001); 
        %------------------------------------------    
        posx.sampleImage = sampleImg(img,initstate,trparams.init_postrainrad,0,100000);
        negx.sampleImage = sampleImg(img,initstate,1.5*trparams.srchwinsz,4+trparams.init_postrainrad,trparams.init_negnumtrain);
        %------------------------------------------------weight of the positive instance    
        posx.w = exp(-((posx.sampleImage.sx-initstate(1)).^2+(posx.sampleImage.sy-initstate(2)).^2));    
        %-----------------------------------    
        %--------------------------------------------------Update all the features in pool
        selector = 1:M;
        posx.feature = getFtrVal(iH,posx.sampleImage,ftr,selector);
        negx.feature = getFtrVal(iH,negx.sampleImage,ftr,selector);
        %--------------------------------------------------
        [posx.mu,posx.sig,negx.mu,negx.sig] = weakClfUpdate(posx,negx,posx.mu,posx.sig,negx.mu,negx.sig,lRate);% update distribution parameters
        posx.pospred = weakClassifier(posx,negx,posx,selector);
        negx.negpred = weakClassifier(posx,negx,negx,selector);
        %--------------------------------------------------
        selector = clfWMilBoostUpdate(posx,negx,numSel);% select the most discriminative weak classifiers 
        time = time + toc();
    end
    precisions = precision_plot(positions, groundtruth_rect, 'MIL', 0);
    all_precisions(k,:) = precisions;
    all_fps(k,:) = num / time;
    fprintf('%s\n',videos{k});
end
%save('mil.mat','all_precisions','all_fps');


%%