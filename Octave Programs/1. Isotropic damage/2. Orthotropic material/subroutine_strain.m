function [sig6,A66,sdvl]=subroutine_strain(eps6,sdvl,ttype)



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
d1      = sdvl(2);
d2      = sdvl(3);
d3      = sdvl(4);
F_f     = sdvl(5);
F_m     = sdvl(6);
F_z     = sdvl(7);

eta = 0;


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

eps_11_f_t = sig_11_f_t / ((1 -yz_zy) / (young_y*young_z*delta));
eps_11_f_c = sig_11_f_c / ((1 -yz_zy) / (young_y*young_z*delta));
eps_22_f_t = sig_22_f_t / ((1 -zx_xz) / (young_x*young_z*delta));
eps_22_f_c = sig_22_f_c / ((1 -zx_xz) / (young_x*young_z*delta));
eps_33_f_t = sig_33_f_t / ((1 -xy_yx) / (young_x*young_y*delta));
eps_33_f_c = sig_33_f_c / ((1 -xy_yx) / (young_x*young_y*delta));
eps_12_f   = sig_12_f / g_xy;
eps_13_f   = sig_13_f / g_yz;
eps_23_f   = sig_23_f / g_xz;


%  Damage initiation criteria %

if eps(1) >= 0

  F_f_new  =  eps(1)/eps_11_f_t;

elseif eps(1) < 0
   
  F_f_new   =  eps(1)/eps_11_f_c;
  
endif




if eps(2) >= 0 
  
  F_m_new   =  eps(2)/eps_22_f_t; 
 
elseif eps(2) < 0
  
  F_m_new   =  eps(2)/eps_22_f_c;

endif



if eps(3) >= 0

  F_z_new   =  eps(3)/eps_33_f_t;

elseif eps(3) < 0

  F_z_new   =  eps(3)/eps_33_f_c;
  
endif


%%%%%%%% To make sure damage initiation criteria is greater than or equal to previous step  %%%%%%%%%%

if F_f_new >= F_f
    F_f = F_f_new;
else
    F_f = F_f;
end

if F_m_new >= F_m
    F_m = F_m_new;
else
    F_m = F_m;
end

if F_z_new >= F_z
    F_z = F_z_new;
else
    F_z = F_z;
end



% Create an empty stress vector
sig6 = zeros(6,1);

%%%%%%%%  Check whether damage has initiated or not  %%%%%%%%%

if F_f<1 && F_m<1 && F_z<1
  
    % Compute stress using Hookes law  %
    for i = 1:6
       for j = 1:6
          sig6(i) = sig6(i) + (1 + eta - damage)*C(i,j)*eps(j); 
       end
    end
    
    C_T  = (1 + eta - damage)*C;


    
else
    fprintf('yes\n');

%%%%%%  Terms in damage evolution equations  %%%%%%%%
    if eps(1) >= 0

       epsilon_f = eps_11_f_t
       P1 = 25;
    elseif eps(1) < 0
   
       epsilon_f = eps_11_f_c; 
        P1 = -25;
    endif
    
    
    
    if eps(2) >= 0 
      
      epsilon_m = eps_22_f_t;
      P2 = 25;
    elseif eps(2) < 0
  
      epsilon_m = eps_22_f_c;
      P2 = -25;
    endif

    
    
    if eps(3) >= 0

      epsilon_z =  eps_33_f_t;
      P3 = 25;
    elseif eps(3) < 0

      epsilon_z =  eps_33_f_c; 
      P3 = -25;
    endif   

   
    
    
    
    %%%%%%%% Damage evolution equations  %%%%%%%%%%
    
    if F_f > 1
      
      d1_new =  1  -  (exp(-P1*(eps(1) - epsilon_f)));     %d1
      
     if d1_new >= d1
          d1 = d1_new;
      else
          d1 = d1;
      end
    else
      d1 = 0;      
    endif
    
    
    if F_m > 1
       
      d2_new = 1  -  (exp(-P2*(eps(2) - epsilon_m)));    %d2
      
      if d2_new >= d2
          d2 = d2_new;
      else
          d2 = d2;
      end
    else
      d2 = 0;
    endif
    
    
    if F_z > 1
      
      d3_new  = 1  -  (exp(-P3*(eps(3) - epsilon_z)));    %d3
      
      if d3_new >= d3
          d3 = d3_new;
      else
          d3 = d3;
      end
    else
      d3 = 0;      
    endif

    damage_new = 1  - ((1 - d1)*(1 - d2)*(1 - d3))

% To make sure the damage evolution is greater than or equal to zero
    if damage_new >= damage
      damage = damage_new;
    else
      damage = damage;
    end    

    for i = 1:6
      for j = 1:6
        sig6(i) = sig6(i) +  (1 + eta - damage)*C(i,j)*eps(j);
      end
    end
    
%%%%% First term of the tangent stiffness %%%%%   
    a = (1 + eta - damage)*C;

%%%%%% Second term of tangent stiffness  %%%%%    
    b = [ P1*exp(-P1*(eps(1)-epsilon_f))*(1 - d2)*(1 - d3); P2*exp(-P2*(eps(2)-epsilon_m))*(1 - d1)*(1 - d3); P3*exp(-P3*(eps(3)-epsilon_z))*(1 - d2)*(1 - d1); 0;0;0];
    
    c = C*eps; 
    
    d = c*b';
    
%%%%  Tangent stiffness   %%%%
    C_T = a - d;
  
endif
  
  
  
  

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
        [sig6per,Adummy,sdvldummy] = subroutine_strain(epsper,sdvl,0);
        %Simple differential quotient
        A66_num(:,ieps)=(sig6per-sig6)/hper;
        
    end
    A66=A66_num;

end




% store history variables
sdvl(1) = damage;
sdvl(2) = d1;
sdvl(3) = d2;
sdvl(4) = d3;
sdvl(5) = F_f;
sdvl(6) = F_m;
sdvl(7) = F_z;

end
