function precisions = precision_plot(positions, ground_truth, title, show)
%PRECISION_PLOT
%   Calculates precision for a series of distance thresholds (percentage of
%   frames where the distance to the ground truth is within the threshold).
%   The results are shown in a new figure if SHOW is true.
%
%   Accepts positions and ground truth as Nx2 matrices (for N frames), and
%   a title string.
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/

	
	max_threshold = 50;  %used for graphs in the paper
	
	
	precisions = zeros(max_threshold, 1);
	
	if size(positions,1) ~= size(ground_truth,1),
% 		fprintf('%12s - Number of ground truth frames does not match number of tracked frames.\n', title)
		
		%just ignore any extra frames, in either results or ground truth
		n = min(size(positions,1), size(ground_truth,1));
		positions(n+1:end,:) = [];
		ground_truth(n+1:end,:) = [];
	end
	
	%calculate distances to ground truth over all frames
	distances = sqrt((positions(:,1) - ground_truth(:,1)).^2 + ...
				 	 (positions(:,2) - ground_truth(:,2)).^2);
	distances(isnan(distances)) = [];

	%compute precisions
	for p = 1:max_threshold,
		precisions(p) = nnz(distances <= p) / numel(distances);
	end
	
	%plot the precisions
	if show == 1,
		figure('Name',['Precisions - ' title])
		plot(precisions, 'k-', 'LineWidth',2)
		xlabel('Threshold'), ylabel('Precision')
    end
	
    %compute precision based on the PETS2009 Challenge
    %center (x,y) and width, height
    correctArea = 0;
    totalArea = 0;
    for i =1 : size(positions,1),
        h1 = [positions(i,[1,2]) - positions(i,[3,4])/2, positions(i,[3,4])];
        h2 = [ground_truth(i,[1,2]) - ground_truth(i,[3,4])/2, ground_truth(i,[3,4])];
        
   
        correctArea = correctArea + 1e-10 * rectint(h1,h2);
        totalArea = totalArea + 1e-10 * (positions(i,3)*positions(i,4) + ...
                ground_truth(i,3)*ground_truth(i,4) - 2*correctArea);
    end
    %precisions = correctArea / totalArea;
end

