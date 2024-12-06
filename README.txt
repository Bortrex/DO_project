ENVIRONMENT NAME: "."
RUN FILE: main.jl

to run this repository 
either do it through VScode by doing 
    - user@1:~$ code .
or through terminal:
    - user@1:~$ julia
    - julia > ]
    - (@v1.10) pkg> activate . // to activate ENVIRONMENT and load packages
    - (DO_Project) pkg> instantiate // to install packages if needed
    THEN 
    - BACKSPACE key
    - julia > exit()
    either use mode_type 1 for model
    - user@1:$ julia --project main.jl mode 1 
    either use mode_type 2 for heuristic
    - user@1:$ julia --project main.jl mode 2
    
