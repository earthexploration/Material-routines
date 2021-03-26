function [sig6,A66,sdvl]=vmises_numerical_tangent(eps6,sdvl,ttype)


tol=1e-8;

% material parameters
matp      = inputmat();
xE        = matp(1);            % Young's modulus
xnu       = matp(2);            % Poisson's ratio
xsigy0    = matp(3);            % initial yield stress
xk        = xE/(3*(1-2*xnu));   % bulk modulus

% Lames constants
lambda  =  xE * xnu / ((1 + xnu) * (1 - 2*xnu));
xmu  = xE/(2*(1+xnu));     % shear modulus


% general 
ii = [1,2,3,1,2,1];
jj = [1,2,3,2,3,3];
xid = eye(3);

% restore the strain tensor in voigt notation
eps = [eps6(1); eps6(2); eps6(3); eps6(4); eps6(5); eps6(6);];

% restore the strain tensor
eps_tensor = [eps6(1) eps6(4)/2 eps6(6)/2;
              eps6(4)/2 eps6(2) eps6(5)/2;
              eps6(6)/2 eps6(5)/2 eps6(3)];

% restore the internal variables at tn
damage  = sdvl;
%fprintf('previous damage value %f\n', damage );

C = zeros(6,6);
% ELastic stiffness matix (6*6)
C(1,1) = lambda + 2*xmu;
C(1,2) = lambda;
C(1,3) = lambda;
C(1,4) = 0;
C(1,5) = 0;
C(1,6) = 0;
C(2,1) = lambda;
C(2,2) = lambda + 2*xmu;
C(2,3) = lambda;
C(2,4) = 0;
C(2,5) = 0;
C(2,6) = 0;
C(3,1) = lambda;
C(3,2) = lambda;
C(3,3) = lambda + 2*xmu;
C(3,4) = 0;
C(3,5) = 0;
C(3,6) = 0;
C(4,1) = 0;
C(4,2) = 0;
C(4,3) = 0;
C(4,4) = xmu;
C(4,5) = 0;
C(4,6) = 0;
C(5,1) = 0;
C(5,2) = 0;
C(5,3) = 0;
C(5,4) = 0;
C(5,5) = xmu;
C(5,6) = 0;
C(6,1) = 0;
C(6,2) = 0;
C(6,3) = 0;
C(6,4) = 0;
C(6,5) = 0;
C(6,6) = xmu;


% Maximum failure strain in 11 direction
epsilon_f = xsigy0 / C(1,1);

%fprintf('epsilon_f %f\n',epsilon_f);

% Create an empty stress vector
sig6 = zeros(6,1);
eta = 1e-5;
P = 2500;               %parameter in damage evolution

%Check if the strain in 11 direction is smaller than failure strain

if norm(eps(1)) < epsilon_f
    
  % Compute stress using Hookes law
  for i = 1:6
    for j = 1:6
      sig6(i) = sig6(i) +  (1+eta-damage)*C(i,j)*eps(j);  % At the beginning of loading damage will be zero, while unloading damage value is the value recorded during the end of tensile loading
       
    end
  end
  C_T =  (1+eta-damage)*(2*xmu*getP4sym() +  xk*t2_otimes_t2(xid,xid));
  

elseif norm(eps(1)) >= epsilon_f
  
  damage_new = 1 - (exp(-(eps(1)-epsilon_f)*P));    % Damage evolution
  
% To make sure the damage evolution is greater than or equal to zero
  if damage_new >= damage
    damage = damage_new;
  else
    damage = damage;
  end
  
  %fprintf('Current damage value %f\n', damage);
 
  for i = 1:6
    for j = 1:6
      sig6(i) = sig6(i) +  (1 + eta - damage)*C(i,j)*eps(j);
    end
  end
  
  
%%%%%%%%%   Tangent stiffness   %%%%%%%%%
 
% 4th order elstic stiffness tensor for isotropic material
  C_full = 2*xmu*getP4sym() +  xk*t2_otimes_t2(xid,xid);

  a = (1 + eta - damage)*C_full;
    
% Second term of the tangent stiffness
  b1 = P*exp(-P*(eps(1)-epsilon_f));     % partial derivative of damage w.r.t to e11
  b2 = [1,0,0;0,0,0;0,0,0];              % partial derivative of e11 w.r.t to strain tensor
  
  b = b1*b2;
  
  c = t4_contr_t2( C_full,eps_tensor);     %Double contration of 4th order C with 2nd order strain tensor
  
  d = t2_otimes_t2(c,b);                   %Dyadic product of above two terms(c and d)
  
  
  %Tangent stiffness
  C_T = a - d;

end
%fprintf('C11 %f\n', C(1,1));
%fprintf('s22 %f\n', sig6(2));

A66=zeros(6,6);

% restore stiffness tensor as matrix
ii = [1,2,3,1,2,1];
jj = [1,2,3,2,3,3];


if ttype==0
    for i=1:6
        for j=1:6
        A66(i,j) = C_T(ii(i),jj(i),ii(j),jj(j));
        end
    end
elseif ttype == 1
    hper=1e-8;
    %perturbation of the strain entries (here total strain, maybe this has to be modified)
    for ieps=1:1:length(eps6)
        epsper=eps6;
        epsper(ieps)=epsper(ieps)+hper;
        %recursiv call of your material routine with ttype=0 to avoid
        %endless loop
        %Calculate perturbed stress, sdv are not overwritten
        [sig6per,Adummy,sdvldummy]=vmises(epsper,sdvl,0);
        %Simple differential quotient
        A66_num(:,ieps)=(sig6per-sig6)/hper;
        
    end
    A66=A66_num;
end


%end

% store history variables
sdvl = damage;
end
