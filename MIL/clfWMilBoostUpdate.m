function selector = clfWMilBoostUpdate(posx,negx,NumSel)
%- Select features by online weighted multiple instance learning boosting method.
%- NumSel: number of selected features.
%- Changed by Kaihua Zhang, on May 18th, 2011
%- Revised by Kaihua Zhang, 10/12/2011
%- Revised by Kaihua Zhang, 8/8/2012
[row,numpos] = size(posx.feature);
[row,numneg] = size(negx.feature);
Hpos = zeros(1,numpos);
Hneg = zeros(1,numneg);
count = 1;
selector = zeros(1,NumSel);
%-------------------------------------------
for s = 1:NumSel
    %---------------------------------------
    %--------Our weighted MIL
         psigf = posx.w.*sigmf(Hpos,[1 0]);
         pll = -(psigf.*(1-psigf))/sum(psigf);
         nsigf =sigmf(Hneg,[-1 0]);
         nll = (nsigf.*(1-nsigf))/sum(nsigf);   
    %--------------------------------Our feature selection criterion
         poslikl = (posx.pospred*pll')';
         neglikl = (negx.negpred*nll')';
         likl = poslikl+neglikl;         
        %----------------------------------------------------              
        [likAsc,ind] = sort(likl,2);        
        for k=1:length(ind)
           if ~sum(selector == ind(k))
               selector(count) = ind(k);
               count = count + 1;
               break;
           end
        end 
        Hpos = Hpos + posx.pospred(selector(s),:);
        Hneg = Hneg + negx.negpred(selector(s),:); 
end