function [ out ] = mocalc( atoms, xyz, totalcharge, options )
% Write a function mocalc that will contain the SCF algorithm. In it, 
% read in the basis set definition and calculate all the integrals by 
% calling the appropriate functions. The interface of the function should 
% be:
%
% Input:
%   atoms              list of element numbers (array with K elements); 
%                      e.g. [6 8] for CO 
%
%   xyz                Kx3 array of Cartesian coordinates of a nuclei, in
%                      �ngstr�m.
%
%   totalcharge        total charge of the molecule, in elementary charges
%
%   options            a structure that contains several fields
%        .basisset     string specifying the basis set, e.g. '6-31G', 
%                      'cc-pVDZ', 'STO-3G' SCF convergence tolerance 
%                      for the energy (hartrees)
%        .tolEnergy    SCF convergence tolerance for the energy (Hartrees)
%        .tolDensity   SCF convergence tolerance for the density ( a0^-3)
%
% Output:
%   out                a structure that contains several fields:
%        .S            overlap matrix (M�M)
%        .T            kinetic energy matrix (M�M)
%        .Vne          electron-nuclear attraction matrix (M�M)
%        .Vee          electron-electron repulsion matrix (M�M)
%        .ERI          4D array of electron-electron repulsion integrals 
%                      (M�M�M�M) 
%        .epsilon      MO energies (1�M), in hartrees, in ascending order,
%                      occupied and virtual orbitals
%        .C            MO coefficient matrix (M�M), of occupied and 
%                      virtual orbitals, sorted in ascending order of 
%                      orbital energy
%        .P            density matrix (M�M) sorted in ascending order of 
%                      orbital energy
%        .E0           electronic ground-state energy of the molecule, in 
%                      hartrees
%        .Etot         total ground-state energy (including nuclear-
%                      nuclear repulsion), in hartrees
%        .basis        list of basis functions, as generated by makebasis


% Get Basis Set
basissetdef = basisread(options.basisset);
basis = makebasis(atoms,xyz,basissetdef);

% Initialize structure for output, include S, T, Vne, Vee generation
out = struct(...
            'S',         int_overlap(basis),...
            'T',         int_kinenergy(basis),...
            'Vne',       int_attraction(basis),...
            'Vee',       int_repulsion(basis),...
            'epsilon',   0,...
            'C',         0,...
            'P',         0,...
            'E0',        0,...
            'Etot',      0,...
            'basis',     basis);


nMOs = (sum(atoms) - totalcharge)/2;
a0 = 0.52917721067;

% Fock Matrix: F = T + V_ne + V_ee.  For the initial guess, I am dropping
% all of the interaction terms.
h = out.T + out.Vne;
F = h;
P = zeros(length(F)); % start with P as zeros

% Get Nuclear-Nuclear repulsion energy
Vnn = 0;
for c = 1:length(atoms)
    for d = c+1:length(atoms)
        Vnn = Vnn + ((atoms(c) * atoms(d)) / (norm(xyz(c,:) - xyz(d,:))/a0));
    end
end
Etotal = Vnn;

% SCF Loop
ERI = out.Vee;
diffE = 1000 + options.tolEnergy;
diffP = 1000 + options.tolDensity;
count = 0;
while or(diffE > options.tolEnergy, diffP > options.tolDensity)
    
    Elast = Etotal;
    Plast = P;
    Vee = zeros(size(F));
    E0 = 0;
    count = count+1;
    for mu = 1:length(F)
        for nu = 1:length(F)
            
            for kappa = 1:length(F)
                for lambda = 1:length(F)
                    Vee(mu,nu) = Vee(mu,nu) + P(kappa,lambda) * ...
                        (ERI(mu,nu,lambda,kappa) + 0.5 * ...
                        ERI(mu,kappa,lambda,nu));
                end
            end
            E0 = E0 + (0.5 * P(mu, nu) * (2*h(mu, nu) + Vee(mu, nu)));
        
        end
    end
    % Update Fock
    F = h + Vee;
    
    % Solve Roothan
    [C, epsilon] = eig(F, out.S);
    
    % Sort MO coeff matrix
    [epsilon, eI] = sort(diag(epsilon));
    C = C(:,eI);
    
    % Normalize C
    normal = sqrt(diag(C'*out.S*C));
    for c=1:length(C)
        C(:,c) = C(:,c)/normal(c);
    end
    
    % Update Density
    P = 2 * (C(:,1:nMOs) * C(:,1:nMOs)');

    Etotal = E0 + Vnn
    
    diffE = abs(Elast - Etotal);
    diffP = max(abs(P(:)-Plast(:)));
end
%spy(round(P-Plast, 6))
out.C = C;
out.P = P;
out.epsilon = epsilon;
out.E0 = E0;
out.Etot = Etotal;
end

