
files = 'd:\PETS2009\Crowd_PETS09\S2\L1\Time_12-34\View_001\';
dirs = dir(files);
    videos = {dirs.name};
    videos(strcmp('.', videos) | strcmp('..', videos) | ...
                 strcmp('anno', videos) ) = [];

    n = numel(videos);
parpool
parfor i=1:n,
    im = imread(sprintf('%s%s', files, videos{i}));
    imshow(im);
end
poolobj = gcp('nocreate');
delete(poolobj);