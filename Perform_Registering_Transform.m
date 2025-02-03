% This function performs linear+CPD transformation (X -> X')
% X can be a point set (Nxd array), 2D image (2d array), or 3D image stack (3d array).
% type='points', '2D_images', or '3D_images'. 
% T is a structure that defines the transformation obtained with Register_linear_cpd3.m
% X_registered has the same format as X.
% If type='points' transformation must be forward. 
% If type='2D_images' or '3D_images', transformation must be inverse.

function X_registered=Perform_Registering_Transform(X,type,T)


if strcmp(type,'points') 
    D=pdist2(T.points,X);
    G=exp(-D.^2./2/T.sigma^2);
    V=-G'*T.C_tilde./size(T.points,1);
    X_registered = X*T.A'+T.b + V;

elseif strcmp(type,'2D_images')
    X_registered=zeros(size(X),'like',X);
    [xx,yy]=ind2sub(size(X),1:numel(X));
    xy=[xx(:),yy(:)];
    clear xx yy

    D=pdist2(T.points,xy);
    G=exp(-D.^2./2/T.sigma^2);
    V=-G'*T.C_tilde./size(T.points,1);
    xy_prime = round(xy*T.A'+T.b + V);
    clear D G V xy

    ind=(xy_prime(:,1)>=1 & xy_prime(:,1)<=size(X,1) & xy_prime(:,2)>=1 & xy_prime(:,2)<=size(X,2));
    ind2=xy_prime(ind,1)+(xy_prime(ind,2)-1).*size(X,1);
    X_registered(ind)=X(ind2);

elseif strcmp(type,'3D_images')
    X_registered=zeros(size(X),'like',X);
    [xx,yy,zz]=ind2sub(size(X),1:numel(X));
    xyz=[xx(:),yy(:),zz(:)];
    clear xx yy zz

    D=pdist2(T.points,xyz);
    G=exp(-D.^2./2/T.sigma^2);
    V=-G'*T.C_tilde./size(T.points,1);
    xyz_prime = round(xyz*T.A'+T.b + V);
    clear D G V xyz

    ind=(xyz_prime(:,1)>=1 & xyz_prime(:,1)<=size(X,1) & xyz_prime(:,2)>=1 & xyz_prime(:,2)<=size(X,2) & xyz_prime(:,3)>=1 & xyz_prime(:,3)<=size(X,3));
    ind2=xyz_prime(ind,1)+(xyz_prime(ind,2)-1).*size(X,1)+(xyz_prime(ind,3)-1).*(size(X,1)*size(X,2));
    X_registered(ind)=X(ind2);
end




