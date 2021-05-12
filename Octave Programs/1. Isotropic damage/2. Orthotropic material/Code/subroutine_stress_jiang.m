function [sig6,A66,sdvl]=subroutine_stress_jiang(eps6,sdvl,ttype)



%%%% material parameters %%%%

matp       = inputmat();
young_x    = matp(1);
young_y    = matp(2);
young_z    = matp(3);
pr_xy      = matp(4);
pr_yz      = matp(5);
pr_xz      = matp(6);
g_xy       = matp(7);
g_yz       = matp(8);
g_xz       = matp(9);
sig_11_f_t = matp(10);
sig_11_f_c = matp(11);
sig_22_f_t = matp(12);
sig_22_f_c = matp(13);
sig_33_f_t = matp(12);
sig_33_f_c = matp(13);
sig_12_f   =  sig_13_f = sig_23_f = matp(14);
G_c_1      = matp(15);
G_c_2      = matp(17);
G_c_3      = matp(17);
L_c        = matp(19);



pr_yx = (young_y * pr_xy) / young_x;
pr_zy = (young_z * pr_yz) / young_y;
pr_zx = (young_z* pr_xz) / young_x;
xy_yx = pr_xy*pr_yx;
yz_zy = pr_yz*pr_zy;
zx_xz = pr_zx*pr_xz;
xyz   = 2*pr_xy*pr_yz*pr_zx;
E_xyz = young_x*young_y*young_z;
delta = (1 - (xy_yx) - (yz_zy) - (zx_xz) - (xyz)) / E_xyz;



% restore the strain tensor in voigt notation
eps = [eps6(1); eps6(2); eps6(3); eps6(4); eps6(5); eps6(6);];

% restore the strain tensor
eps_tensor = [eps6(1) eps6(4)/2 eps6(6)/2;
              eps6(4)/2 eps6(2) eps6(5)/2;
              eps6(6)/2 eps6(5)/2 eps6(3)];


              
% restore the internal variables at tn
damage  = sdvl(1);
F_f     = sdvl(2);



C = zeros(6,6);
% Elastic stiffness matix (6*6)
C(1,1) = (1 -yz_zy) / (young_y*young_z*delta);
C(1,2) = (pr_yx + pr_zx*pr_yz) / (young_y*young_z*delta);
C(1,3) = (pr_zx + pr_yx*pr_zy) / (young_y*young_z*delta);
C(1,4) = 0;
C(1,5) = 0;
C(1,6) = 0;
C(2,1) = (pr_yx + pr_zx*pr_yz) / (young_y*young_z*delta);
C(2,2) = (1 -zx_xz) / (young_x*young_z*delta);
C(2,3) = (pr_zy + pr_zx*pr_xy) / (young_x*young_z*delta);
C(2,4) = 0;
C(2,5) = 0;
C(2,6) = 0;
C(3,1) = (pr_zx + pr_yx*pr_zy) / (young_y*young_z*delta);
C(3,2) = (pr_zy + pr_zx*pr_xy) / (young_x*young_z*delta);
C(3,3) = (1 -xy_yx) / (young_x*young_y*delta);
C(3,4) = 0;
C(3,5) = 0;
C(3,6) = 0;
C(4,1) = 0;
C(4,2) = 0;
C(4,3) = 0;
C(4,4) = g_xy;
C(4,5) = 0;
C(4,6) = 0;
C(5,1) = 0;
C(5,2) = 0;
C(5,3) = 0;
C(5,4) = 0;
C(5,5) = g_yz;
C(5,6) = 0;
C(6,1) = 0;
C(6,2) = 0;
C(6,3) = 0;
C(6,4) = 0;
C(6,5) = 0;
C(6,6) = g_xz;



%%%%%%%%%%%%  Compute stress   %%%%%%%%%%%%%

% Create an empty effective stress vector
sig6_eff = zeros(6,1);
for i = 1:6
   for j = 1:6
      sig6_eff(i) = sig6_eff(i) + C(i,j)*eps(j); 
   end
end
sig6_eff(1)



%  Damage initiation criteria %

if sig6_eff(1) >= 0

  F_f_new   =  sig6_eff(1)/sig_11_f_t;

elseif sig6_eff(1) < 0
   
  F_f_new   =  sig6_eff(1)/sig_11_f_c;
  
endif




%%%%%%%% To make sure damage initiation criteria is greater than or equal to previous step  %%%%%%%%%%

if F_f_new >= F_f
    F_f = F_f_new;
else
    F_f = F_f;
endif





%%%%%%%%  Check whether damage has initiated or not  %%%%%%%%%

if F_f<=1 
    sig6 = zeros(6,1);
    sig6 = sig6_eff;
    
else
    
    fprintf('yes\n');
%%%%%%  Terms in damage evolution equations  %%%%%%%%
    if sig6_eff(1) >= 0
      g_0  =  sig_11_f_t/(2*young_x);
      M_0  = 2*g_0*L_c/(G_c_1 - (g_0*L_c));
    elseif sig6_eff(1) < 0
      g_0  =  sig_11_f_c/(2*young_x);
      M_0  = 2*g_0*L_c/(G_c_1 - (g_0*L_c));   
    endif
    
    
    %%%%%%%% Damage evolution equation  %%%%%%%%%%
    
    damage_new =  1  -  (  exp(M_0*(1 - F_f))/F_f  );     %d1

% To make sure the damage evolution is greater than or equal to zero
    if damage_new >= damage
      damage = damage_new;
    else
      damage = damage;
    endif    
    sig6 = zeros(6,1);
    sig6 =  (1-damage)*sig6_eff;

    
    

endif
fprintf('stress\n');
sig6(1)  
  
  
  
C_T = zeros(6,6);
if ttype==0
    for i=1:6
        for j=1:6
        A66(i,j) = C_T(i,j);
        end
    end
    
    
%%%%%%%%%%%   Numerical tangent   %%%%%%%%%%%%%%

elseif ttype == 1
    hper=1e-8;
    %perturbation of the strain entries (here total strain, maybe this has to be modified)
    for ieps=1:1:length(eps6)
        epsper=eps6;
        epsper(ieps)=epsper(ieps)+hper;
        %recursiv call of your material routine with ttype=0 to avoid
        %endless loop
        %Calculate perturbed stress, sdv are not overwritten
        [sig6per,Adummy,sdvldummy] = subroutine_stress_jiang(epsper,sdvl,0);
        fprintf('NP\n');
        sig6per(1)
        %Simple differential quotient
        A66_num(:,ieps)=(sig6per-sig6)/hper;
        
    end
    A66=A66_num;

end




% store history variables
sdvl(1) = damage;
sdvl(2) = F_f;
end
