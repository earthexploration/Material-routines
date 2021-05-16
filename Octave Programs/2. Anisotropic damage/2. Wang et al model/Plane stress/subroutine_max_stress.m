function [sig3,A33,sdvl]=subroutine_max_stress(eps3,sdvl,ttype)% material parametersmatp      = inputmat_planestress();young_x   = matp(1);young_y   = matp(2);pr_xy     = matp(3);g_xy      = matp(4);sig_11_f_t = matp(5);sig_11_f_c = matp(6);sig_22_f_t = matp(7);sig_22_f_c = matp(8);sig_12_f   = matp(9);G_c_1      = matp(10);G_c_2      = matp(12);G_c_3      = matp(13);L_c        = matp(14);pr_yx     = (young_y * pr_xy) / young_x;% restore the strain tensor in voigt notationeps = [eps3(1); eps3(2); eps3(3);];% restore the internal variables at tnd1  = sdvl(1);d2  = sdvl(2);d3  = 1 - ((1 -d1)*(1 - d2));F_f = sdvl(3);F_m = sdvl(4);C = zeros(3,3);% Elastic stiffness matix (6*6)C(1,1) = (young_x/(1 - pr_xy*pr_yx));C(1,2) = (pr_xy * young_y /(1 - pr_xy*pr_yx));C(1,3) = 0;C(2,1) = (pr_xy * young_y /(1 - pr_xy*pr_yx));C(2,2) = (young_y/(1 - pr_xy*pr_yx));C(2,3) = 0;C(3,1) = 0;C(3,2) = 0;C(3,3) = g_xy;eps_11_f_t = sig_11_f_t / (young_x/(1 - pr_xy*pr_yx));eps_11_f_c = sig_11_f_c / (young_x/(1 - pr_xy*pr_yx));eps_22_f_t = sig_22_f_t / (young_y/(1 - pr_xy*pr_yx));eps_22_f_c = sig_22_f_c / (young_y/(1 - pr_xy*pr_yx));eps_12_f   = sig_12_f / g_xy;%%%%%%%%%%%%  Compute stress   %%%%%%%%%%%%%% Create an empty stress vectorsig3_eff = zeros(3,1);for i = 1:3   for j = 1:3      sig3_eff(i) = sig3_eff(i) + C(i,j)*eps(j);    endend%  Damage initiation criteria %if sig3_eff(1) >= 0  F_f_new   =  sig3_eff(1)/sig_11_f_t;elseif sig3_eff(1) < 0     F_f_new   =  sig3_eff(1)/sig_11_f_c;  endifif sig3_eff(2) >= 0     F_m_new   =  sig3_eff(2)/sig_22_f_t;  elseif sig3_eff(2) < 0    F_m_new   =  sig3_eff(2)/sig_22_f_c;endifsig3 = zeros(3,1);%%%%%%%% To make sure damage initiation criteria is greater than or equal to previous step  %%%%%%%%%%if F_f_new >= F_f    F_f = F_f_new;else    F_f = F_f;endif F_m_new >= F_m    F_m = F_m_new;else    F_m = F_m;endsig3 = zeros(3,1);%%%%%%%%  Check whether damage has initiated or not  %%%%%%%%%if F_f<=1 && F_m<=1       sig3 = sig3_eff;        D  =  1  -  ((1 - d1)*(1 - d2)*pr_xy*pr_yx);    C_T = zeros(3,3);    C_T(1,1) = young_x*(1 - d1)*(1/D);    C_T(1,2) = pr_xy * young_y*(1 - d1)*(1 - d2)*(1/D);    C_T(1,3) = 0;    C_T(2,1) = pr_xy * young_y*(1 - d1)*(1 - d2)*(1/D);    C_T(2,2) = young_y*(1 - d2)*(1/D);    C_T(2,3) = 0;    C_T(3,1) = 0;    C_T(3,2) = 0;    C_T(3,3) = g_xy*(1 - d3);       else%%%%%%  Terms in damage evolution equations  %%%%%%%%    if sig3_eff(1) >= 0       k1 = (-sig_11_f_t*eps_11_f_t*L_c)/G_c_1;           elseif sig3_eff(1) < 0          k1 = (-sig_11_f_c*eps_11_f_c*L_c)/G_c_1;            endif               if sig3_eff(2) >= 0              k2 = (-sig_22_f_t*eps_22_f_t*L_c)/G_c_2;         elseif sig3_eff(2) < 0         k2 =  (-sig_22_f_c*eps_22_f_c*L_c)/G_c_2;          endif        %%%%%%%% Damage evolution equations  %%%%%%%%%%        if F_f**2 > 1            d1_new =  1  - ((exp(k1*(F_f - 1)))/F_f);     %d1             if d1_new > d1          d1 = d1_new;      else          d1 = d1;      end    endif            if F_m**2 > 1             d2_new = 1  - ((exp(k2*(F_m - 1)))/F_m);     %d2            if d2_new > d2          d2 = d2_new;      else          d2 = d2;      end          endif      d3  = 1 - ((1 -d1)*(1 - d2));    %%%%%%   Inverse of damage effect tensor (M_inverse)  %%%%%%%%      M_inv = zeros(3,3);    M_inv(1,1) = (1-d1);    M_inv(2,2) = (1-d2);    M_inv(3,3) = (1-d3);    %%%%%%%   Find nominal stress from effective stress  (sigma = (1 - D)*sigma_eff)   %%%%%%%%    for i = 1:3       for j = 1:3          sig3(i) = sig3(i) + M_inv(i,j)*sig3_eff(j);       end    end                  %%%%%%%%%%%   Degraded stiffness  %%%%%%%%%%%%    D  =  1  -  ((1 - d1)*(1 - d2)*pr_xy*pr_yx);    C_d = zeros(3,3);    C_d(1,1) = young_x*(1 - d1)*(1/D);    C_d(1,2) = pr_xy * young_y*(1 - d1)*(1 - d2)*(1/D);    C_d(1,3) = 0;    C_d(2,1) = pr_xy * young_y*(1 - d1)*(1 - d2)*(1/D);    C_d(2,2) = young_y*(1 - d2)*(1/D);    C_d(2,3) = 0;    C_d(3,1) = 0;    C_d(3,2) = 0;    C_d(3,3) = g_xy*(1 - d3);             if d1 == 0            C_T_1 = zeros(3,3);             else          %%%%%%%%% First term C_T_1 ((d_C_d/d1 : eps) outerProduct (d_d1/d_epsilon))   %%%%%%%%%%      C_T_1_a = zeros(3,1);      C_T_1_a = [-sig3_eff(1); 0; (1-d2)*sig3_eff(3);];            %%%%%%%%%%%%%%%%   Derivative of d1 with respect to strain (d_d1/d_epsilon)  %%%%%%%%%%%%%            %%%%%%   For Tension   %%%%%%      if sig3_eff(1) > 0        C_T_1_b  = [ ((1 - k1*F_f)/(F_f**2 * sig_11_f_t * (1 - d1) ))*exp(k1*(F_f - 1))*C(1,1); ((1 - k1*F_f)/(F_f**2 * sig_11_f_t * (1 - d1) ))*exp(k1*(F_f - 1))*C(1,2); 0;];                      %%%%%   For Compression  %%%%%%      elseif sig3_eff(1) < 0        C_T_1_b  =  [ ((1 - k1*F_f)/(F_f**2 * sig_11_f_c * (1 - d1) ))*exp(k1*(F_f - 1))*C(1,1); ((1 - k1*F_f)/(F_f**2 * sig_11_f_c * (1 - d1) ))*exp(k1*(F_f - 1))*C(1,2); 0;];             endif              C_T_1  =  C_T_1_a*C_T_1_b';    endif              if d2 == 0            C_T_2  =  zeros(3,3);         else            %%%%%%%%% Second term C_T_2 ((d_C_d/d2 : eps) outerProduct (d_d2/d_epsilon))   %%%%%%%%%%      C_T_2_a = zeros(3,1);      C_T_2_a = [0;  -sig3_eff(2);  (1-d1)*sig3_eff(3);];                %%%%%%%%%%%%%%%%   Derivative of d2 with respect to strain (d_d2/d_epsilon)  %%%%%%%%%%%%%      %%%%%%   For Tension   %%%%%%         if sig3_eff(2)  >= 0                        C_T_2_b  = [((1 - k2*F_m)/(F_m**2 * sig_22_f_t * (1 - d2) ))*exp(k2*(F_m - 1))*C(2,1); ((1 - k2*F_m)/(F_m**2 * sig_22_f_t * (1 - d2) ))*exp(k2*(F_m - 1))*C(2,2); 0;];              %%%%%   For Compression  %%%%%%        elseif sig3_eff(2) < 0                  C_T_2_b  =  [((1 - k2*F_m)/(F_m**2 * sig_22_f_c * (1 - d2) ))*exp(k2*(F_m - 1))*C(2,1); ((1 - k2*F_m)/(F_m**2 * sig_22_f_c * (1 - d2) ))*exp(k2*(F_m - 1))*C(2,2); 0;];                endif      C_T_2  =  C_T_2_a*C_T_2_b';      C_T_2    endif                    %%%%%%%%%  Tangent stiffness %%%%%%%%%    C_T  =  C_d + C_T_1 + C_T_2 ;  endif  A33=zeros(3,3);if ttype==0    for i=1:3        for j=1:3        A33(i,j) = C_T(i,j);        end    endelseif ttype == 1    hper=1e-8;    %perturbation of the strain entries (here total strain, maybe this has to be modified)    for ieps=1:1:length(eps3)        epsper=eps3;        epsper(ieps)=epsper(ieps)+hper;        %recursiv call of your material routine with ttype=0 to avoid        %endless loop        %Calculate perturbed stress, sdv are not overwritten        [sig3per,Adummy,sdvldummy]=subroutine_max_stress(epsper,sdvl,0);        %Simple differential quotient        A33_num(:,ieps)=(sig3per-sig3)/hper;            end    A33=A33_num;end% store history variablessdvl(1) = d1;sdvl(2) = d2;sdvl(3) = F_f;sdvl(4) = F_m;end