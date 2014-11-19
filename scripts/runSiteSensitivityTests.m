% Last updated by Robert Kopp, robert-dot-kopp-at-rutgers-dot-edu, Sun Nov 16 16:51:00 EST 2014

%% do data sensitivity tests

reoptimize=1;

firstyears=[0    0   400 800  1200 1600 1800 1900];
lastyears= [1800 400 800 1200 1600 1800 1900 2000];

wdat = datasets{5};

sitesets0 = {'All','NWAtlantic','NEAtlantic','NAtlantic'};
latbounds = [ -90 90 ; 0 90 ; 0 90 ; 0 90];
longbounds = [ -180 180 ; -125 -30 ; -30 30 ; -125 30];
sitelist = setdiff(wdat.siteid,0);
clear sitesetsub0;
for qqq=1:size(longbounds,1)
    sub=find((wdat.sitecoords(:,1)>=latbounds(qqq,1)).*(wdat.sitecoords(:,1)<=latbounds(qqq,2)));
    sub=intersect(sub,find(((wdat.sitecoords(:,2))>=longbounds(qqq,1)).*((wdat.sitecoords(:,2))<= longbounds(qqq,2))));
    sitesetsub0{qqq}=wdat.siteid(sub);
end

clear sitesets sitesetsub;
for qqq=1:length(sitesets0)
    sitesets{qqq,1} = ['+' sitesets0{qqq} '+GSL'];
    sitesets{qqq,2} = ['+' sitesets0{qqq} '-GSL'];
    sitesets{qqq,3} = ['-' sitesets0{qqq} '+GSL'];
    sitesets{qqq,4} = ['-' sitesets0{qqq} '-GSL'];
    
    sitesetsub{qqq,2} = sitesetsub0{qqq};
    sitesetsub{qqq,1} = union(0,sitesetsub{qqq,2});
    sitesetsub{qqq,4} = setdiff(sitelist,sitesetsub0{qqq});
    sitesetsub{qqq,3} = union(0,sitesetsub{qqq,4});
end

ms=wmodelspec;
ms.thet0=thetTGG{jj}(1:end-1);
startcompact = thetTGG{jj}(end);

fid1=fopen(['sens_theta' labl '.tsv'],'w');
fid2=fopen(['sens_GSLrates' labl '.tsv'],'w');

for qqq=1:size(sitesetsub,1)
    for rrr=1:size(sitesetsub,2)
        
        disp(sitesets{qqq,rrr});
        
        datsub = find(ismember(wdat.datid,sitesetsub{qqq,rrr}));
        sitesub = find(ismember(wdat.siteid,sitesetsub{qqq,rrr}));
        wd=SubsetDataStructure(wdat,datsub,sitesub);
        
        dothet=thetTGG{jj};
        
        if length(datsub)>0
            if reoptimize
                [dothet]=OptimizeHoloceneCovariance(wd,ms,[3.0],trainfirsttime(end),trainrange(end),1e6,startcompact);  
            end
        else
            datsub=find(wdat.datid==0); datsub=datsub(end);
            sitesub=find(wdat.siteid==0);
            wd=SubsetDataStructure(wdat,datsub,sitesub);
            wd.dY = 100000;
            wd.Ycv = wd.dY^2;
        end
        
        
        clear wdef;
        wdef.sites=[0 1e6 1e6];
        wdef.names={'GSL'};
        wdef.names2={'GSL'};
        wdef.firstage=0;
        wdef.oldest=0;
        wdef.youngest=2014;
        trainsub=find(wd.limiting==0);
        wtestt=0:100:2000;
        [wf,wsd,wV,wloc]=RegressHoloceneDataSets(wd,wdef,ms,dothet,trainsub,noiseMasks(1,:),wtestt,refyear,collinear);        

        [wfslope,wsdslope,wfslopediff,wsdslopediff,wdiffplus,wdiffless]=SLRateCompare(wf,wV,wloc.sites,wloc.reg,wloc.X(:,3),firstyears,lastyears);
        
        
        if (qqq==1) && (rrr==1)

            fprintf(fid1,'Trainset');
            fprintf(fid2,'Trainset');

            for pp=1:length(firstyears)
                fprintf(fid2,'\tRate (avg, %0.0f-%0.0f)\t2s',[firstyears(pp) lastyears(pp)]);
            end
            for pp=1:length(wdiffplus)
                fprintf(fid2,['\tRate Diff. (avg, %0.0f-%0.0f minus ' ...
                              '%0.0f-%0.0f)\t2s'],[firstyears(wdiffplus(pp)) ...
                                    lastyears(wdiffplus(pp)) firstyears(wdiffless(pp)) lastyears(wdiffless(pp))]);
            end
            fprintf(fid2,'\n');
        end
        
        
        fprintf(fid1,sitesets{qqq,rrr});
        fprintf(fid2,sitesets{qqq,rrr});
        

        
        for pp=1:length(firstyears)
            fprintf(fid2,'\t%0.2f',[wfslope(1,pp) 2*wsdslope(1,pp)]);
        end
        for pp=1:length(wdiffplus)
            fprintf(fid2,'\t%0.2f',[wfslopediff(1,pp) 2*wsdslopediff(1,pp)]);
        end
        
        fprintf(fid1,'\t%0.2f',dothet);
        
        fprintf(fid1,'\n');
        fprintf(fid2,'\n');
        
    end
end

fclose(fid1);
fclose(fid2);