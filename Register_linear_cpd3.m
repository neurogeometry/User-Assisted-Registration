% This function performs registration of a point set X to point set Y 
% when the correspondences of points are known. The registration is done
% with a linear + nonlinear (CPD) transformation, T(x) = Ax + b +V(x), which
% registers the corresponding points exactly. Four types of linear transformations
% are considered: translation (x+b), rigid (Rx+b, det(R)=1, no reflection), 
% similarity (Ax+b, A=sR, s>0, det(R)=1, no reflection), and affine (Ax+b).
% The details are provided in the related manuscript.

% Input parameters:
% X is Nxd array of coordinates
% Y is Nxd array of coordinates
% sigma is the coherence parameter, higher sigma --> greater coherence
% 0<=lambda<=1 is the multiplier of E_linear and (1-lambda) is the multiplier of E_cpd
% lambda is not used for translation and rigid (can use any value)
% method: 'translation+cpd', 'rigid+cpd', 'similarity+cpd', 'affine+cpd'
% plt = 1 to plot the results

% Output transformation and costs:
% T.method: 'translation+cpd', 'rigid+cpd', 'similarity+cpd', 'affine+cpd'  
% T.points: fiducial points that define the transformation, Nxd array
% T.A is dxd matrix
% T.b is 1xd translation vector
% T.C_tilde is Nxd deformation field
% T.lambda = lambda
% T.sigma = sigma
% E_linear is the cost of linear transformation
% E_cpd is the cost of cpd transformation


function [T,E_linear,E_cpd] = Register_linear_cpd3(X,Y,sigma,lambda,method,plt)

N=size(X,1);
d=size(X,2);
D=pdist2(X,X);
G=exp(-D.^2./2/sigma^2); %./(2*pi*sigma^2)^(d/2);

Xav=sum(G\X,1)./sum(G\ones(N,1),1);
Yav=sum(G\Y,1)./sum(G\ones(N,1),1);
delX=X-Xav;
delY=Y-Yav;

Qxx=delX'*(G\delX);
if det(Qxx)==0
    disp('Matrix Qxx is close to singular. Results may be inaccurate.')
    Qxx=Qxx+diag(ones(1,d).*(10^-12*max(1,trace(Qxx))));
end
Qxy=delX'*(G\delY);
Qyy=delY'*(G\delY);

[U_linear,S_linear,V_linear]=svd(Qxx\Qxy);
I_prime_linear=diag([ones(1,d-1),det(U_linear*V_linear')]);
Norm_linear=sum(diag((S_linear-I_prime_linear).^2));
Norm_cpd=sum(diag(Qxx-2.*Qxy+Qyy));

T.method=method;
T.points=X;
T.lambda=lambda;
T.sigma=sigma;
if strcmp(method,'translation+cpd')
    disp('Parameter lambda is not used in this method')
    R=diag(ones(1,d));
    T.A=R;
    T.b=-Xav+Yav;
elseif strcmp(method,'rigid+cpd')
    disp('Parameter lambda is not used in this method')
    [U,~,V]=svd(Qxy);
    R=V*U';
    if det(R)<0 % A contains an inversion, take the next best rigid transformation
        I_prime=diag([ones(1,d-1),-1]);
        R=V*I_prime*U';
        disp('The optimal orthogonal transformation contains an inversion.')
        disp('The results shown are for the optimal rigid transformation.')
    end
    T.A=R;
    T.b=-Xav*T.A'+Yav;
elseif strcmp(method,'similarity+cpd')
    [U,~,V]=svd(Qxy);
    R=V*U';
    if det(R)<0 % A contains an inversion, take the next best rigid transformation
        I_prime=diag([ones(1,d-1),-1]);
        R=V*I_prime*U';
        disp('The optimal s*orthogonal*x+b transformation contains an inversion.')
        disp('The results shown are for the optimal s*R*x+b transformation.')
    end
    s=(lambda/Norm_linear*d+(1-lambda)/Norm_cpd.*trace(R*Qxy))/(lambda/Norm_linear*d+(1-lambda)/Norm_cpd.*trace(Qxx));
    T.A=s.*R;
    T.b=-Xav*T.A'+Yav;
elseif strcmp(method,'affine+cpd')
    [U,~,V]=svd((lambda/Norm_linear.*diag(ones(1,d))+(1-lambda)/Norm_cpd.*Qxx)\Qxy);
    R=V*U';
    if det(R)<0 % R contains an inversion, take the next best rigid transformation
        I_prime=diag([ones(1,d-1),-1]);
        R=V*I_prime*U';
        disp('The optimal affine transformation contains an inversion.')
        disp('The results shown are for the best affine transformation with det(A)>0.')
    end    
    T.A=(lambda/Norm_linear.*R+(1-lambda)/Norm_cpd.*Qxy')/(lambda/Norm_linear.*diag(ones(1,d))+(1-lambda)/Norm_cpd.*Qxx);
    T.b=-Xav*T.A'+Yav;
else
    error('Unknown method')
end

T.C_tilde=N.*(G\(X*T.A'+T.b-Y));
E_linear=sum((T.A-R).^2,[1,2])/Norm_linear;
E_cpd=trace(T.A*Qxx*T.A'-2.*T.A*Qxy+Qyy)/Norm_cpd;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plt==1
    V_x=-G'*T.C_tilde./N;
    L=X*T.A'+T.b;
    Xp=L+V_x;
    V_norm=V_x./repmat((sum(V_x.^2,2)).^0.5,1,d);
    figure
    if d==3
        plot3(X(:,1),X(:,2),X(:,3),'r*'), hold on
        plot3(Y(:,1),Y(:,2),Y(:,3),'b*')
        plot3(Xp(:,1),Xp(:,2),Xp(:,3),'ro')
        line([X(:,1),X(:,1)+V_norm(:,1)]',[X(:,2),X(:,2)+V_norm(:,2)]',[X(:,3),X(:,3)+V_norm(:,3)]','Color','k')
        %line([X(:,1),X(:,1)+m.*(L(:,1)-X(:,1))]',[X(:,2),X(:,2)+m.*(L(:,2)-X(:,2))]',[X(:,3),X(:,3)+m.*(L(:,3)-X(:,3))]','Color','g')
    elseif d==2
        plot(X(:,1),X(:,2),'r*'), hold on
        plot(Y(:,1),Y(:,2),'b*')
        plot(Xp(:,1),Xp(:,2),'ro')
        line([X(:,1),X(:,1)+V_norm(:,1)]',[X(:,2),X(:,2)+V_norm(:,2)]','Color','k')
        %line([X(:,1),X(:,1)+m.*(L(:,1)-X(:,1))]',[X(:,2),X(:,2)+m.*(L(:,2)-X(:,2))]','Color','g')
    end
    axis equal, box on
    legend({'point set X','point set Y','point set Xp','V(x)'})
    title([method,': ', 'E_L = ', num2str(E_linear), ', E_{cpd} = ', num2str(E_cpd), ', E = ', num2str(lambda.*E_linear+(1-lambda).*E_cpd)])
end