// HW 7 P 2----------------------

// Clear and Close Everything
clear; clc; close; close; close; close;

// Independent Parameters ------------------------------------------------
gamma_a     = 1.4;
gamma_e     = 1.3;
R           = 287; // (j/(kg*K))
M           = 1.8;
P_a         = 12112; // (Pa)
T_a         = 216.650; // (K)
T_max       = 1500; // (K)
h_c         = 43124000; // (j/kg)
FA_st       = 0.06;
T_max_ab   = 2000; // (K)
P_e         = P_a; // (Pa)
eff_dif     = 0.9;
eff_comp    = 0.9; 
eff_burn    = 0.98;
eff_turb    = 0.92;
eff_ab      = 0.95;
eff_nozz    = 0.98;
r_c         = [2:2:60];
r_b         = 0.97;
r_ab        = 0.97;

// Dependent Parameters --------------------------------------------------
Po_3        = zeros(1,30); // (Pa)
To_3_i      = zeros(1,30); // (K)
To_3_r      = zeros(1,30); // (K)
W_c_in      = zeros(1,30); //(W)
FA_b        = zeros(1,30);
eq_ratio    = zeros(1,30);
W_t_out     = zeros(1,30); // (W)
Po_4        = zeros(1,30); // (Pa)
To_5_i      = zeros(1,30); // (K)
To_5_r      = zeros(1,30); // (K)
Po_5        = zeros(1,30); // (Pa)
Po_6        = zeros(1,30); // (Pa)
FA_ab       = zeros(1,30); 
//To_6_r      = zeros(1,30); // (K)
To_7_r      = zeros(1,30); // (K)
T_7_i       = zeros(1,30); // (K)
T_7_r       = zeros(1,30); // (K)
u_e         = zeros(1,30); // (m/s)
M_e         = zeros(1,30);
A_ratio     = zeros(1,30);
TSFC        = zeros(1,30); // (kg/(N*s))
I           = zeros(1,30); // (N*s/kg)
eff_therm   = zeros(1,30);
eff_propul  = zeros(1,30);
eff_overall = zeros(1,30);

// Calculate specific heat at constant pressure---------------------------
cp_a        = (gamma_a/(gamma_a-1))*R;
cp_e        = (gamma_e/(gamma_e-1))*R;

// Ambient conditions-----------------------------------------------------
Po_a        = P_a*(1+(gamma_a-1)/2*M^2)^(gamma_a/(gamma_a-1));
To_a        = T_a*(1+(gamma_a-1)/2*M^2);
u           = M*sqrt(gamma_a*R*T_a);

// Diffuser Stage (a-2)---------------------------------------------------
To_2_r      = To_a;
To_2_i      = eff_dif*(To_2_r-T_a)+T_a;
Po_2        = P_a*(To_2_i/T_a)^(gamma_a/(gamma_a-1));

// Compressor Stage-(2-3)-------------------------------------------------
Po_3        = r_c.*Po_2;
To_3_i      = r_c.^((gamma_a-1)/gamma_a).*To_2_r;
To_3_r      = ((To_3_i-To_2_r)./eff_comp)+To_2_r;
W_c_in      = cp_a.*(To_3_r-To_2_r);

// Burner Stage-(3-4)-----------------------------------------------------
// Verify that FA_b <= FA_st
FA_b        = ((T_max./To_3_r)-1)./(((eff_burn.*h_c)./(cp_e.*To_3_r))-(T_max./To_3_r));
eq_ratio    = FA_b./FA_st;
for i       = 1:30,
    if eq_ratio <= 1 then
        To_4_r = T_max;
    else
        To_4_r(i) = 1.0./(1+FA_st).*((eff_burn.*h_c./cp_e)+To_3_r(i));
    end,
end

Po_4        = r_b.*Po_3;

// Turbine Stage-(4-5)----------------------------------------------------
W_t_out     = W_c_in;
To_5_r      = To_4_r-(W_t_out./((1+FA_b).*cp_e));
To_5_i      = To_4_r-((To_4_r-To_5_r)./eff_turb);
Po_5        = Po_4.*(To_5_i/To_4_r).^(gamma_e./(gamma_e-1));

// Afterburner Stage-(5-6)------------------------------------------------
Po_6        = r_ab.*Po_5;
FA_ab       = ((1+FA_b).*(T_max_ab-To_5_r))./((eff_ab.*h_c/cp_e)-T_max_ab);
eq_ratio  = (FA_b+FA_ab)./FA_st;
for i = 1:30,
    if eq_ratio <= 1 then
        To_6_r = T_max_ab;
    else
        FA_ab(i) = FA_st-FA_b(i);
        To_6_r(i) = (eff_ab.*h_c.*FA_ab(i)+cp_e.*(FA_b(i)+1).*To_5_r(i))./(cp_e.*(FA_st+FA(i)+1));
    end,
end


// Nozzle Stage -(6-7)----------------------------------------------------
To_7_r      = To_6_r;
Po_7        = Po_6;
P_7         = P_e;
T_7_i       = To_6_r.*(P_7./Po_6).^((gamma_e-1)./gamma_e);
T_7_r       = To_6_r-(eff_nozz.*(To_6_r-T_7_i));
u_e         = sqrt(2.*eff_nozz.*(gamma_e./(gamma_e-1)).*R.*To_6_r.*(1-(P_a./Po_6).^((gamma_e-1)./gamma_e)));
M_e         = u_e./sqrt(gamma_e.*R.*T_7_r);
A_ratio     = 1.0./M_e.*((2/(gamma_e+1)).*(1+((gamma_e-1)./2.0).*M_e.^2)).^((gamma_e+1)./(2.0.*(gamma_e-1)));

// Calculate Specific Thrust; TSFC; and Efficiencies;---------------------
I           = ((1+FA_b+FA_ab).*u_e-u);
TSFC        = (FA_b+FA_ab)./I;
eff_therm   = ((1+FA_b+FA_ab).*u_e.^2-u.^2)./(2.0.*(FA_b+FA_ab).*h_c);
eff_propul  = (I.*u)./((1+FA_b+FA_ab).*(u_e.^2.0./2)-(u.^2.0./2));
eff_overall = eff_therm.*eff_propul;

// Plot Graphs------------------------------------------------------------
f0 = scf(5); //creates figure with id==0 and make it the current one
f1 = scf(6); //creates figure with id==1 and make it the current one
f2 = scf(7);
f3 = scf(8);
f4 = scf(9);

// Plot Specific Thrust---------------------------------------------------
scf(f0);
subplot(311);
plot(r_c,I, 'r');
xtitle("Specific Thurst with Afterburner VS Compressor Pressure Ratio","r_c","Specific Thurst(N*s/Kg)");
//a=get("current_axes")
//a.data_bounds=[1,500;6,1220];

// plot TSFC--------------------------------------------------------------
subplot(312);
plot(r_c,TSFC, 'g');
xtitle("TSFC with Afterburner VS Compressor Pressure Ratio","r_c","TSFC(Kg/N*s)");

// plot area ratio--------------------------------------------------------
subplot(313);
plot(r_c,A_ratio, 'r');
xtitle("Area Ratio with Afterburner VS Compressor Pressure Ratio","r_c","Area Ratio");

// Plot Temperature Across TurboJet---------------------------------------
scf(f1);
subplot(111);
plot(r_c,To_3_r, 'b');
plot(r_c,To_5_r, 'c');
plot(r_c,T_7_r, 'm');
xtitle("Stagnation Temperature with Afterburner VS Compressor Pressure Ratio","r_c","Temperature (K)");
leg=legend(['To_3_r';'To_5_r';'T_7_r'],[4]);
//a=get("current_axes")
//a.data_bounds=[1,2300;6,2800];

// Plot Temperature Across TurboJet---------------------------------------
scf(f2);
subplot(111);
plot(r_c,Po_3, 'b');
plot(r_c,Po_4, 'c');
plot(r_c,Po_5, 'm');
xtitle("Stagnation Pressure with Afterburner VS Compressor Pressure Ratio","r_c","Pressure (Pa)");
leg=legend(['Po_3';'Po_4';'Po_5'],[4]);
//a=get("current_axes")
//a.data_bounds=[1,2300;6,2800];

// plot efficiencies------------------------------------------------------
scf(f3); 
subplot(111);
plot(r_c,eff_therm, 'r');
plot(r_c,eff_propul, 'b');
plot(r_c,eff_overall, 'g');
xtitle("Efficiencies with Afterburner VS Compressor Pressure Ratio","r_c","Effeciency");
leg=legend(['Thermal Efficiency';'Propulsive Efficiency';'Overall Efficiency'],[4]);

// Plot Exit Mach number--------------------------------------------------
scf(f4);
subplot(111);
plot(r_c,M_e, 'r');
xtitle("Exit Mach Number with Afterburner VS Compressor Pressure Ratio","r_c","M");
