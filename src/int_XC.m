function [ Vxc, Exc, rhoInt ] = int_XC( basis, P, MolGrid, flag )
% INT_XC() Calulates the exchange-correlation functional for DFT using the
% LDA approximation.
%   INPUTS:
%       basis = basis set from structure array of mocalc output
%       P = MxM Density matrix
%       DGrid = molcular grid
%       flag = string specifying functional i.e 'SVWN3'
%
%   OUTPUTS:
%       Vxc = MxM exchange-correlation potential matrix
%       Exc = exchange-correlation energy
%       rhoInt = Integral of density over allspace. Equal to N electrons.
%
%

rhoInt = 0;
Vxc = zeros(size(basis));
Exc = 0;

% Calculate rho(r) from grid
for iGrid = 1:numel(MolGrid.weights)
    
    r = MolGrid.xyz(iGrid,:);
    w = MolGrid.weights(iGrid);
    
    if w < 1e-10
        continue
    end
    
    rho = 0;

    base = zeros(numel(basis),1);
    
    for mu = 1:numel(basis)
        ksum = 0;
        for k = 1:numel(basis(mu).d)
            ksum = ksum + basis(mu).d(k)*basis(mu).N(k)*...
                exp(-basis(mu).alpha(k)*norm(r-basis(mu).A)^2);
        end
        base(mu) = (r(1)-basis(mu).A(1))^(basis(mu).a(1))*...
            (r(2)-basis(mu).A(2))^(basis(mu).a(2))*...
            (r(3)-basis(mu).A(3))^(basis(mu).a(3))*...
            ksum;
    end
    
    for mu = 1:numel(basis)
        for nu = 1:numel(basis)
            rho = rho + P(mu,nu)*base(mu)*base(nu);
        end
    end
    
    if rho < 1e-10
        continue
    end
    
    % Final rhoInt value
    rhoInt = rhoInt + w*rho;
    
    [ec, vc] = VWN(rho, flag);
    
    eps_xc = (-3/4*(3/pi)^(1/3)*rho^(1/3)) + ec;
    
    Exc = Exc + eps_xc*rho*w;

    temp_Vxc = zeros(numel(basis));
    
    for mu = 1:numel(basis)
        for nu = 1:numel(basis)
            temp_Vxc(mu,nu) = base(mu)*(vc - (3/pi*rho)^1/3)*base(nu);
        end
    end
    
   
    Vxc = Vxc + temp_Vxc*w;
    
end

end


function vxs = xvslater(rho)
    vxs = -(3/pi*rho)^1/3;
end

% Correlation functionals
function [Ec_vwn, Vc_vwn] = VWN(rho, flag)
    if strcmp(flag, 'VWN3')
        A = 0.310907;
        b = 13.0720;
        c = 42.7198;
        x0 = -0.409286;
    elseif strcmp(flag, 'VWN5')
        A = 0.310907;
        b = 3.72744;
        c = 12.9352;
        x0 = -0.10498;
    else
        disp('Unsupported functional specified')
    end
    Q = sqrt(4*c-b^2);
    xi_0 = x0^2 + b*x0 + c;
    x = sqrt((3/(4*pi*rho))^(1/3));
    xi = x^2 + b*x + c;
    eta = atan(Q/(2*x+b));
    
    Ec_vwn = A*( log((x^2)/xi) + 2*b*eta/Q - (b*x0/xi_0) * ...
                    ( log(((x-x0)^2)/xi) + (2*(2*x0 + b)*eta)/Q));
                
    Vc_vwn = -(1/3) * ( (A*(c*(x-x0) - b*x*x0)) / (xi*(x-x0)) ) + Ec_vwn;
    
end

















